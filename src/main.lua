local Promise = require("src/promise")
local async = require("src/async-await").async
local await = require("src/async-await").await

return {
  Promise = Promise,
  async = async,
  await = await,
}
