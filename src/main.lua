local eventLoop = require("src/eventLoop")
local Promise = require("src/promise")
local async = require("src/async-await").async
local await = require("src/async-await").await

return {
  eventLoop = eventLoop,
  Promise = Promise,
  async = async,
  await = await,
}
