
require("framework.functions")

GET = ngx.req.get_uri_args()
if ngx.req.get_method() == "POST" then
    POST = ngx.req.get_post_args()
else
    POST = {}
end
