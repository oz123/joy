(import tester :prefix "" :exit true)
(import "src/joy/router" :prefix "")


(def ok {:status 200 :body ""})
(defn home [request] ok)
(defn accounts [request] ok)
(defn account [request]
  {:status 200 :body (get-in request [:params :id])})


(defn wildcard [request]
  (request :wildcard))


(defn auth-code [request]
  "auth-code")


(defn auth-code-p [request]
  (request :params))


(defroutes test-routes
  [:get "/" home]
  [:get "/test" home :qs]
  [:get "/accounts" accounts]
  [:get "/accounts/:id" account]
  [:get "/anchor" home :anchor]
  [:get "/anchor/:id" home :anchor-id]
  [:get "/accounts/:id/edit" identity :with-params]
  [:get "/auth-code" auth-code]
  [:patch "/accounts/:id" identity :accounts/patch]
  [:get "/auth-code/:id" auth-code-p]
  [:get "/wildcard/*" wildcard]
  [:get "/wild/*/card/*" wildcard :wildcard-2]
  [:get "/*" wildcard])


(defroutes test-routes-2
  [:get "/" home])


(deftest
  (test "root path"
    (= {:status 200 :body ""}
       ((handler test-routes) {:method :get :uri "/"})))

  (test "get handler from routes"
    (= {:status 200 :body ""}
       ((handler test-routes) {:method :get :uri "/accounts"})))

  (test "get handler from routes 2"
      (= {:status 200 :body "1"}
         ((handler test-routes) {:method :get :uri "/accounts/1"})))

  (test "url-for with a route name"
    (= (url-for :home) "/"))

  (test "url-for with a query string"
    (= (url-for :qs {:? {"a" "1"}})
       "/test?a=1"))

  (test "url-for with an anchor string and a query string"
    (= (url-for :anchor {:? {"a" "1"} "#" "anchor"})
       "/anchor?a=1#anchor"))

  (test "url-for with url params an anchor string and a query string"
    (= (url-for :anchor-id {:id 1 :? {"a" "1"} "#" "anchor"})
       "/anchor/1?a=1#anchor"))

  (test "url-for with wildcard routes"
    (= "/wild/1/card/2" (url-for :wildcard-2 {:* [1 2]})))

  (test "redirect-to with a function"
    (= (freeze
        (redirect-to :home))
       {:status 302 :body " " :headers {"Location" "/"}}))

  (test "redirect-to with a name and params"
    (= (freeze
        (redirect-to :with-params {:id 100}))
       {:status 302 :body " " :headers {"Location" "/accounts/100/edit"}}))

  (test "action-for with a name and params"
    (= (freeze
        (action-for :accounts/patch {:id 100}))
       {:_method :patch :method :post :action "/accounts/100"}))

  (test "wildcard route"
    (deep= @["hello/world"]
           ((handler test-routes) {:method :get :uri "/wildcard/hello/world"})))

  (test "query string route"
    (= "auth-code"
       ((handler test-routes) {:method :get :uri "/auth-code?code=12345"})))

  (test "query string route with a param"
    (deep= @{:id "1"}
           ((handler test-routes) {:method :get :uri "/auth-code/1?code=12345"})))

  (test "wildcard route with query string"
    (deep= @["a/really/long/path"]
           ((handler test-routes) {:method :get :uri "/a/really/long/path?test=true"})))

  (test "wildcard route with static parts"
    (deep= @["1" "2"]
           ((handler test-routes) {:method :get :uri "/wild/1/card/2"})))

  (test "wildcard route with static parts and a slashes at the end"
    (deep= @["1" "a/really/long/url"]
           ((handler test-routes) {:method :get :uri "/wild/1/card/a/really/long/url"})))

  (test "404"
    (nil? ((handler test-routes-2) {:method :get :uri "/what"}))))
