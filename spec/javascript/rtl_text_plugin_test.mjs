import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import test from "node:test"

const source = await readFile(
  new URL(
    "../../app/javascript/maps_maplibre/utils/rtl_text_plugin.js",
    import.meta.url,
  ),
  "utf8",
)
const { registerRTLTextPlugin } = await import(
  `data:text/javascript;base64,${Buffer.from(source).toString("base64")}`
)

test("registers the local worker plugin once across repeated map initializations", async () => {
  let status = "unavailable"
  const requests = []
  const maplibre = {
    getRTLTextPluginStatus: () => status,
    setRTLTextPlugin: async (...args) => {
      requests.push(args)
      status = "deferred"
    },
  }
  await registerRTLTextPlugin(maplibre, "/assets/rtl-digest.js")
  await registerRTLTextPlugin(maplibre, "/assets/rtl-digest.js")
  assert.deepEqual(requests, [["/assets/rtl-digest.js", true]])
})

for (const status of ["deferred", "loading", "loaded"]) {
  test(`keeps an existing ${status} registration`, () => {
    registerRTLTextPlugin(
      {
        getRTLTextPluginStatus: () => status,
        setRTLTextPlugin: () => assert.fail("duplicate registration"),
      },
      "/assets/rtl.js",
    )
  })
}

test("contains loading failures and allows retry on the next map", async (t) => {
  t.mock.method(console, "warn", () => {})
  let calls = 0
  const maplibre = {
    getRTLTextPluginStatus: () => "error",
    setRTLTextPlugin: async () => {
      calls++
      if (calls === 1) throw new Error("offline")
    },
  }
  await assert.doesNotReject(registerRTLTextPlugin(maplibre, "/assets/rtl.js"))
  await assert.doesNotReject(registerRTLTextPlugin(maplibre, "/assets/rtl.js"))
  assert.equal(calls, 2)
})
