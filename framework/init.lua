
require("framework.functions")

REQUEST_METHOD = ngx.req.get_method()
GET = ngx.req.get_uri_args()
if REQUEST_METHOD == "POST" then
    -- ngx.req.read_body()
    POST = ngx.req.get_post_args()
else
    POST = {}
end
