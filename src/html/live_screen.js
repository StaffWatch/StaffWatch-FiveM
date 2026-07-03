import {
  CfxTexture,
  LinearFilter,
  Mesh,
  NearestFilter,
  OrthographicCamera,
  PlaneBufferGeometry,
  RGBAFormat,
  Scene,
  ShaderMaterial,
  UnsignedByteType,
  WebGLRenderer,
  WebGLRenderTarget
} from "./three.module.js"

const DEFAULT_QUALITY = {
  width: 640,
  height: 360,
  fps: 15,
  bitrate: 600000
}

let activeSession = null

class GameViewCapture {
  constructor(quality) {
    this.quality = { ...DEFAULT_QUALITY, ...(quality || {}) }
    this.app = document.getElementById("app")
    this.animationFrame = null
    this.running = false
    this.stream = null
  }

  start() {
    const width = this.quality.width
    const height = this.quality.height

    this.camera = new OrthographicCamera(width / -2, width / 2, height / 2, height / -2, -10000, 10000)
    this.camera.position.z = 100
    this.scene = new Scene()
    this.renderTarget = new WebGLRenderTarget(width, height, {
      minFilter: LinearFilter,
      magFilter: NearestFilter,
      format: RGBAFormat,
      type: UnsignedByteType
    })

    const gameTexture = new CfxTexture()
    gameTexture.needsUpdate = true

    const material = new ShaderMaterial({
      uniforms: {
        tDiffuse: { value: gameTexture }
      },
      vertexShader: `
        varying vec2 vUv;
        void main() {
          vUv = vec2(uv.x, 1.0 - uv.y);
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        varying vec2 vUv;
        uniform sampler2D tDiffuse;
        void main() {
          gl_FragColor = texture2D(tDiffuse, vUv);
        }
      `
    })

    const plane = new PlaneBufferGeometry(width, height)
    const quad = new Mesh(plane, material)
    quad.position.z = -100
    this.scene.add(quad)

    this.renderer = new WebGLRenderer({
      alpha: true,
      antialias: false,
      preserveDrawingBuffer: false
    })
    this.renderer.setPixelRatio(1)
    this.renderer.setSize(width, height)
    this.renderer.autoClear = false

    clearElement(this.app)
    this.app.appendChild(this.renderer.domElement)
    this.stream = this.renderer.domElement.captureStream(this.quality.fps)
    const [track] = this.stream.getVideoTracks()
    if (track && "contentHint" in track) {
      track.contentHint = "motion"
    }

    this.running = true
    this.render = this.render.bind(this)
    this.animationFrame = requestAnimationFrame(this.render)
    return this.stream
  }

  render() {
    if (!this.running) return
    this.renderer.clear()
    this.renderer.render(this.scene, this.camera, this.renderTarget, true)
    this.renderer.render(this.scene, this.camera)
    this.animationFrame = requestAnimationFrame(this.render)
  }

  stop() {
    this.running = false
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame)
    }
    this.stream?.getTracks().forEach(track => track.stop())
    this.renderer?.dispose()
    this.renderTarget?.dispose()
    clearElement(this.app)
  }
}

window.addEventListener("message", event => {
  const data = event.data || {}
  if (data.type === "startLiveScreen") {
    startLiveScreen(data.payload)
  } else if (data.type === "stopLiveScreen") {
    stopLiveScreen(data.sessionId, true, "Live screen stopped")
  }
})

async function startLiveScreen(payload) {
  await stopLiveScreen(null, false)
  if (!payload?.sessionId || !payload.webSocketUrl || !payload.publisherToken) {
    return
  }

  let capture = null
  let peer = null

  try {
    capture = new GameViewCapture(payload.quality)
    const stream = capture.start()
    peer = new RTCPeerConnection({
      iceServers: payload.iceServers || [],
      iceTransportPolicy: "relay"
    })

    activeSession = {
      sessionId: payload.sessionId,
      capture,
      peer,
      socket: null,
      offerStarted: false,
      closed: false,
      quality: { ...DEFAULT_QUALITY, ...(payload.quality || {}) }
    }

    stream.getTracks().forEach(track => {
      const sender = peer.addTrack(track, stream)
      applySenderLimits(sender, activeSession.quality.bitrate)
    })

    peer.onicecandidate = event => {
      if (!event.candidate) {
        sendSignal({ type: "ice", candidate: null })
        return
      }
      if (isRelayCandidate(event.candidate.candidate)) {
        sendSignal({ type: "ice", candidate: event.candidate })
      }
    }

    peer.onconnectionstatechange = () => {
      if (peer.connectionState === "connected") {
        reportStatus("LIVE")
      } else if (peer.connectionState === "failed" || peer.connectionState === "disconnected") {
        failLiveScreen("Live screen WebRTC connection failed")
      }
    }

    const socketUrl = new URL(payload.webSocketUrl)
    socketUrl.searchParams.set("sessionId", payload.sessionId)
    socketUrl.searchParams.set("role", "publisher")
    socketUrl.searchParams.set("token", payload.publisherToken)

    const socket = new WebSocket(socketUrl.toString())
    activeSession.socket = socket

    socket.onopen = () => {
      sendSignal({ type: "ready" })
      reportStatus("PUBLISHER_READY")
    }
    socket.onerror = () => failLiveScreen("Live screen signaling failed")
    socket.onclose = () => {
      if (activeSession && !activeSession.closed) {
        failLiveScreen("Live screen signaling closed")
      }
    }
    socket.onmessage = async event => {
      try {
        const message = JSON.parse(event.data)
        if (message.type === "ready") {
          await sendOffer()
        } else if (message.type === "answer" && message.sdp) {
          await peer.setRemoteDescription(message.sdp)
        } else if (message.type === "ice" && message.candidate) {
          await peer.addIceCandidate(message.candidate)
        } else if (message.type === "stop") {
          await stopLiveScreen(payload.sessionId, true, "Live screen stopped")
        } else if (message.type === "status" && (message.status === "stopped" || message.status === "expired")) {
          await stopLiveScreen(payload.sessionId, false)
        } else if (message.type === "error") {
          failLiveScreen(message.message || "Live screen signaling rejected the connection")
        }
      } catch (error) {
        failLiveScreen(error?.message || "Live screen signaling failed")
      }
    }
  } catch (error) {
    peer?.close()
    capture?.stop()
    reportStatusForSession(payload.sessionId, "FAILED", error?.message || "Unable to start live screen capture")
    await stopLiveScreen(payload.sessionId, false)
  }
}

async function sendOffer() {
  if (!activeSession || activeSession.offerStarted) {
    return
  }

  activeSession.offerStarted = true
  reportStatus("PUBLISHER_CONNECTING")
  const offer = await activeSession.peer.createOffer()
  await activeSession.peer.setLocalDescription(offer)
  sendSignal({ type: "offer", sdp: activeSession.peer.localDescription })
}

async function stopLiveScreen(sessionId, report, message) {
  if (!activeSession) {
    return
  }
  if (sessionId && activeSession.sessionId !== sessionId) {
    return
  }

  const session = activeSession
  activeSession = null
  session.closed = true
  session.socket?.close()
  session.peer?.close()
  session.capture?.stop()

  if (report) {
    reportStatusForSession(session.sessionId, "STOPPED", message)
  }
}

function failLiveScreen(message) {
  if (!activeSession) {
    return
  }
  const sessionId = activeSession.sessionId
  reportStatusForSession(sessionId, "FAILED", message)
  stopLiveScreen(sessionId, false)
}

function sendSignal(message) {
  if (activeSession?.socket?.readyState === WebSocket.OPEN) {
    activeSession.socket.send(JSON.stringify(message))
  }
}

function applySenderLimits(sender, bitrate) {
  if (!sender.getParameters || !sender.setParameters) {
    return
  }

  const parameters = sender.getParameters()
  parameters.encodings = parameters.encodings?.length ? parameters.encodings : [{}]
  parameters.encodings[0].maxBitrate = bitrate
  sender.setParameters(parameters).catch(() => {})
}

function isRelayCandidate(candidate) {
  if (!candidate) {
    return true
  }
  return candidate.includes(" typ relay")
}

function reportStatus(status, message) {
  if (!activeSession) {
    return
  }
  reportStatusForSession(activeSession.sessionId, status, message)
}

function reportStatusForSession(sessionId, status, message) {
  const resourceName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "StaffWatch-FiveM"
  fetch(`https://${resourceName}/liveScreenStatus`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json; charset=UTF-8"
    },
    body: JSON.stringify({
      sessionId,
      status,
      message
    })
  }).catch(() => {})
}

function clearElement(element) {
  while (element.firstChild) {
    element.removeChild(element.firstChild)
  }
}
