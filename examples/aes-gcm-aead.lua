local key = string.rep("0", 32)
local iv = string.rep("0", 12)

local to_be_encrypted = "secret"

local aad = "aead aad"

local mode = "aes-256-gcm"
-- local mode = "chacha20-poly1305"
ngx.say("use cipher ", mode)

-- using one shot interface
local cipher = assert(require("resty.openssl.cipher").new(mode))
local encrypted = assert(cipher:encrypt(key, iv, to_be_encrypted, false, aad))
-- OR using streaming interface
assert(cipher:init(key, iv, {
  is_encrypt = true,
}))
assert(cipher:update_aead_aad(aad))
encrypted = assert(cipher:final(to_be_encrypted))

ngx.say("encryption result: ", ngx.encode_base64(encrypted))

local tag = assert(cipher:get_aead_tag())

ngx.say("tag is: ", ngx.encode_base64(tag), " ", #tag)

local _, err = cipher:decrypt(key, iv, encrypted, false, nil, tag)
if err then
  ngx.say("no AAD, decryption failed")
end

local _, err = cipher:decrypt(key, iv, encrypted, false, "wrong", tag)
if err then
  ngx.say("wrong AAD, decryption failed")
end

-- this seems not working for chacha20-poly1305
local _, err = cipher:decrypt(key, iv, encrypted, false, aad, nil)
if err then
  ngx.say("no tag, decryption failed")
end

local _, err = cipher:decrypt(key, iv, encrypted, false, aad, "wrong")
if err then
  ngx.say("wrong tag, decryption failed")
end

-- using one shot interface
local decrypted = assert(cipher:decrypt(key, iv, encrypted, false, aad, tag))
-- OR using streaming interface
assert(cipher:init(key, iv, {
  is_encrypt = false,
}))
assert(cipher:update_aead_aad(aad))
assert(cipher:set_aead_tag(tag))
decrypted = assert(cipher:final(encrypted))

ngx.say("decryption result: ", decrypted)

