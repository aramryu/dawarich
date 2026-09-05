import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import { test } from "node:test"

const source = await readFile(
  new URL(
    "../../app/javascript/maps_maplibre/utils/search_manager.js",
    import.meta.url,
  ),
  "utf8",
)
const testableSource = source
  .replace('import { translate } from "i18n"', "const translate = (key) => key")
  .replace(
    'import { LocationSearchService } from "../services/location_search_service.js"',
    "class LocationSearchService {}",
  )
const moduleUrl = `data:text/javascript;base64,${Buffer.from(testableSource).toString("base64")}`
const { SearchManager } = await import(moduleUrl)

class FakeElement {
  constructor() {
    this.children = []
    this.listeners = new Map()
    this.state = null
    this.value = ""
  }

  addEventListener(type, handler) {
    this.listeners.set(type, handler)
  }

  contains(target) {
    return target === this || this.children.includes(target)
  }
}

test("a result click keeps the rendered visits visible", async () => {
  const documentListeners = new Map()
  globalThis.document = {
    addEventListener(type, handler) {
      documentListeners.set(type, handler)
    },
  }

  const searchInput = new FakeElement()
  const resultsContainer = new FakeElement()
  const clickedResult = {}
  resultsContainer.children = [clickedResult]

  const manager = new SearchManager({ flyTo() {} }, "api-key")
  manager.addSearchMarker = () => {}
  manager.dispatchSearchEvent = () => {}
  manager.showVisitsLoading = () => {
    resultsContainer.children = []
    resultsContainer.state = "loading"
  }
  manager.displayVisitsResults = () => {
    resultsContainer.state = "visits"
  }
  manager.clearResults = () => {
    resultsContainer.state = "cleared"
  }
  manager.service.searchVisits = async () => ({ visits: [] })
  manager.initialize(searchInput, resultsContainer)

  const clickEvent = {
    target: clickedResult,
    composedPath: () => [clickedResult, resultsContainer, document],
  }
  const visitRender = manager.handleResultClick({
    lat: 52.52,
    lon: 13.405,
    name: "Example Town",
  })
  documentListeners.get("click")(clickEvent)

  await visitRender
  await new Promise((resolve) => setTimeout(resolve, 150))

  assert.equal(resultsContainer.state, "visits")
})
