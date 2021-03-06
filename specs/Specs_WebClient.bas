Attribute VB_Name = "Specs_WebClient"
''
' Specs_WebClient
' (c) Tim Hall - https://github.com/VBA-tools/VBA-Web
'
' Specs for WebClient
'
' @author: tim.hall.engr@gmail.com
' @license: MIT (http://www.opensource.org/licenses/mit-license.php)
'
' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ '

Public Function Specs() As SpecSuite
    Set Specs = New SpecSuite
    Specs.Description = "WebClient"
    
    Dim Client As New WebClient
    Dim Request As WebRequest
    Dim Response As WebResponse
    Dim Body As Dictionary
    Dim BodyToString As String
    Dim i As Integer
    Dim Options As Dictionary
    Dim XMLBody As Object
    
    Client.BaseUrl = HttpbinBaseUrl
    Client.TimeoutMs = 5000
    
    ' --------------------------------------------- '
    ' Properties
    ' --------------------------------------------- '
    
    ' BaseUrl
    ' Username
    ' Password
    ' Authenticator
    ' TimeoutMS
    ' ProxyServer
    ' ProxyUsername
    ' ProxyPassword
    ' ProxyBypassList
    
    ' ============================================= '
    ' Public Methods
    ' ============================================= '
    
    ' Execute
    ' --------------------------------------------- '
    With Specs.It("Execute should set method, url, headers, cookies, and body")
        Set Request = New WebRequest
        Request.Resource = "put"
        Request.Method = WebMethod.HttpPut
        Request.AddQuerystringParam "number", 123
        Request.AddQuerystringParam "string", "abc"
        Request.AddQuerystringParam "boolean", True
        Request.AddHeader "X-Custom", "Howdy!"
        Request.AddCookie "abc", 123
        Request.RequestFormat = WebFormat.FormUrlEncoded
        Request.ResponseFormat = WebFormat.Json
        Request.AddBodyParameter "message", "Howdy!"
        
        Set Response = Client.Execute(Request)
        
        .Expect(Response.StatusCode).ToEqual WebStatusCode.Ok
        .Expect(Response.Data("url")).ToEqual "http://httpbin.org/put?number=123&string=abc&boolean=true"
        .Expect(Response.Data("headers")("X-Custom")).ToEqual "Howdy!"
        .Expect(Response.Data("headers")("Content-Type")).ToMatch WebHelpers.FormatToMediaType(WebFormat.FormUrlEncoded)
        .Expect(Response.Data("headers")("Accept")).ToMatch WebHelpers.FormatToMediaType(WebFormat.Json)
        .Expect(Response.Data("headers")("Cookie")).ToMatch "abc=123"
        .Expect(Response.Data("form")("message")).ToEqual "Howdy!"
    End With
    
    With Specs.It("Execute should use Basic Authentication")
        Set Request = New WebRequest
        Request.Resource = "basic-auth/{user}/{password}"
        Request.AddUrlSegment "user", "Tim"
        Request.AddUrlSegment "password", "Secret123"
        
        Set Response = Client.Execute(Request)
        .Expect(Response.StatusCode).ToEqual WebStatusCode.Unauthorized
        
        Client.Username = "Tim"
        Client.Password = "Secret123"
        
        Set Response = Client.Execute(Request)
        .Expect(Response.StatusCode).ToEqual 200
        .Expect(Response.Data("authenticated")).ToEqual True
    End With
    
    ' GetJSON
    ' --------------------------------------------- '
    With Specs.It("should GetJSON")
        Set Response = Client.GetJson("/get")

        .Expect(Response.StatusCode).ToEqual 200
        .Expect(Response.Data).ToNotBeUndefined
        .Expect(Response.Data("headers").Count).ToBeGT 0
    End With
    
    With Specs.It("should GetJSON with options")
        Set Options = New Dictionary
        Options.Add "Headers", New Collection
        Options("Headers").Add WebHelpers.CreateKeyValue("X-Custom", "Howdy!")
        Options.Add "Cookies", New Collection
        Options("Cookies").Add WebHelpers.CreateKeyValue("abc", 123)
        Options.Add "QuerystringParams", New Collection
        Options("QuerystringParams").Add WebHelpers.CreateKeyValue("message", "Howdy!")
        Options.Add "UrlSegments", New Dictionary
        Options("UrlSegments").Add "resource", "get"
        
        Set Response = Client.GetJson("/{resource}", Options)
    
        .Expect(Response.StatusCode).ToEqual WebStatusCode.Ok
        .Expect(Response.Data).ToNotBeUndefined
        .Expect(Response.Data("url")).ToEqual "http://httpbin.org/get?message=Howdy!"
        .Expect(Response.Data("headers")("X-Custom")).ToEqual "Howdy!"
        .Expect(Response.Data("headers")("Cookie")).ToMatch "abc=123"
    End With
    
    ' PostJSON
    ' --------------------------------------------- '
    With Specs.It("should PostJSON")
        Set Body = New Dictionary
        Body.Add "a", 3.14
        Body.Add "b", "Howdy!"
        Body.Add "c", True
        Set Response = Client.PostJson("/post", Body)

        .Expect(Response.StatusCode).ToEqual 200
        .Expect(Response.Data).ToNotBeUndefined
        .Expect(Response.Data("json")("a")).ToEqual 3.14
        .Expect(Response.Data("json")("b")).ToEqual "Howdy!"
        .Expect(Response.Data("json")("c")).ToEqual True

        Set Response = Client.PostJson("/post", Array(3, 2, 1))

        .Expect(Response.StatusCode).ToEqual 200
        .Expect(Response.Data).ToNotBeUndefined
        .Expect(Response.Data("json")(1)).ToEqual 3
        .Expect(Response.Data("json")(2)).ToEqual 2
        .Expect(Response.Data("json")(3)).ToEqual 1
    End With
    
    With Specs.It("should PostJSON with options")
        Set Body = New Dictionary
        Body.Add "a", 3.14
        Body.Add "b", "Howdy!"
        Body.Add "c", True
        
        Set Options = New Dictionary
        Options.Add "Headers", New Collection
        Options("Headers").Add WebHelpers.CreateKeyValue("X-Custom", "Howdy!")
        Options.Add "Cookies", New Collection
        Options("Cookies").Add WebHelpers.CreateKeyValue("abc", 123)
        Options.Add "QuerystringParams", New Collection
        Options("QuerystringParams").Add WebHelpers.CreateKeyValue("message", "Howdy!")
        Options.Add "UrlSegments", New Dictionary
        Options("UrlSegments").Add "resource", "post"
        
        Set Response = Client.PostJson("/{resource}", Body, Options)
    
        .Expect(Response.StatusCode).ToEqual WebStatusCode.Ok
        .Expect(Response.Data).ToNotBeUndefined
        .Expect(Response.Data("url")).ToEqual "http://httpbin.org/post?message=Howdy!"
        .Expect(Response.Data("headers")("X-Custom")).ToEqual "Howdy!"
        .Expect(Response.Data("headers")("Cookie")).ToMatch "abc=123"
        .Expect(Response.Data("json")("a")).ToEqual 3.14
        .Expect(Response.Data("json")("b")).ToEqual "Howdy!"
        .Expect(Response.Data("json")("c")).ToEqual True
    End With
    
    ' SetProxy
    
    ' GetFullUrl
    ' --------------------------------------------- '
    With Specs.It("should GetFullUrl of Request")
        Set Request = New WebRequest
        
        Client.BaseUrl = "https://facebook.com/api"
        Request.Resource = "status"
        .Expect(Client.GetFullUrl(Request)).ToEqual "https://facebook.com/api/status"
        
        Client.BaseUrl = "https://facebook.com/api"
        Request.Resource = "/status"
        .Expect(Client.GetFullUrl(Request)).ToEqual "https://facebook.com/api/status"
        
        Client.BaseUrl = "https://facebook.com/api/"
        Request.Resource = "status"
        .Expect(Client.GetFullUrl(Request)).ToEqual "https://facebook.com/api/status"
        
        Client.BaseUrl = "https://facebook.com/api/"
        Request.Resource = "/status"
        .Expect(Client.GetFullUrl(Request)).ToEqual "https://facebook.com/api/status"
        
        Client.BaseUrl = HttpbinBaseUrl
    End With
    
    ' PrepareHttpRequest
    
    ' PrepareCURL
    ' @internal
    ' --------------------------------------------- '
    With Specs.It("[Mac-only] should PrepareCURLRequest")
#If Mac Then
        Set Client = New WebClient
        Client.BaseUrl = "http://localhost:3000/"
        Client.Username = "user"
        Client.Password = "password"
        Client.ProxyServer = "proxyserver"
        Client.ProxyBypassList = "proxyserver:80, *.github.com"
        Client.ProxyUsername = "proxyuser"
        Client.ProxyPassword = "proxypassword"
        
        Set Request = New WebRequest
        Request.Resource = "text"
        Request.AddQuerystringParam "type", "message"
        Request.Method = HttpPost
        Request.RequestFormat = WebFormat.PlainText
        Request.ResponseFormat = WebFormat.Json
        Request.Body = "Howdy!"
        Request.AddHeader "custom", "Howdy!"
        Request.AddCookie "test-cookie", "howdy"
        
        Dim cURL As String
        
        cURL = Client.PrepareCurlRequest(Request)
        .Expect(cURL).ToMatch "http://localhost:3000/text?type=message"
        .Expect(cURL).ToMatch "-X POST"
        .Expect(cURL).ToMatch "--user user:password"
        .Expect(cURL).ToMatch "--proxy proxyserver"
        .Expect(cURL).ToMatch "--noproxy proxyserver:80, *.github.com"
        .Expect(cURL).ToMatch "--proxy-user proxyuser:proxypassword"
        .Expect(cURL).ToMatch "-H 'Content-Type: text/plain'"
        .Expect(cURL).ToMatch "-H 'Accept: application/json'"
        .Expect(cURL).ToMatch "-H 'custom: Howdy!'"
        .Expect(cURL).ToMatch "--cookie 'test-cookie=howdy;'"
        .Expect(cURL).ToMatch "-d 'Howdy!'"
#Else
        ' (Mac-only)
        .Expect(True).ToEqual True
#End If
    End With
    
    With Specs.It("should handle timeout errors")
        Client.TimeoutMs = 500
        
        Set Request = New WebRequest
        Request.Resource = "delay/{seconds}"
        Request.AddUrlSegment "seconds", "2"
        
        Set Response = Client.Execute(Request)
        .Expect(Response.StatusCode).ToEqual 408
        .Expect(Response.StatusDescription).ToEqual "Request Timeout"
    End With
    
    ' ============================================= '
    ' Errors
    ' ============================================= '
    On Error Resume Next
    
    With Specs.It("should throw 11011 on general error")
        ' Unsupported protocol
        Client.BaseUrl = "unknown://"
        Set Response = Client.Execute(Request)
        
        .Expect(Err.Number).ToEqual 11011 + vbObjectError
        Err.Clear
    End With
    
    Set Client = Nothing
    
    InlineRunner.RunSuite Specs
End Function

