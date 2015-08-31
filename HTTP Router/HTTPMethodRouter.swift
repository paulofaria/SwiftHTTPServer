// HTTPMethodRouter.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

final class HTTPMethodRouter: ServerRouter<HTTPMethodRoute> {

    let fallback: (method: HTTPMethod) -> HTTPRequest throws -> HTTPResponse

    init(fallback: (method: HTTPMethod) -> HTTPRequest throws -> HTTPResponse) {

        self.fallback = fallback

    }

    var respond: HTTPRequest throws -> HTTPResponse {

        return getRespond(
            key: HTTPRequest.methodRouterKey,
            fallback: fallback
        )

    }

}

struct HTTPMethodRoute: ServerRoute {

    let key: HTTPMethod
    let respond: HTTPRequest throws -> HTTPResponse

    init(key: HTTPMethod, respond: HTTPRequest throws -> HTTPResponse) {

        self.key = key
        self.respond = respond

    }

    func matchesKey(key: HTTPMethod) -> Bool {

        return self.key == key

    }

    var respondForKey: (key: HTTPMethod) -> (HTTPRequest throws -> HTTPResponse) {

        return { (key: HTTPMethod) in
            
            return self.respond
            
        }
        
    }
    
}