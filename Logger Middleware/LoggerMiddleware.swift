// LoggerMiddleware.swift
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

extension Middleware {
    
    static func log<Request: CustomColorLogStringConvertible, Response: CustomColorLogStringConvertible>(request: Request, response: Response) {
        
        Log.info(request)
        Log.info(response)
        
    }

    static func logRequest<Request: CustomColorLogStringConvertible, Response>(request: Request) -> RequestMiddlewareResult<Request, Response> {

        Log.info(request)
        return .Request(request)
        
    }

    static func logResponse<Response: CustomColorLogStringConvertible>(response: Response) -> Response {

        Log.info(response)
        return response
        
    }

    static func logRequest<Request, Response>(request: Request) -> RequestMiddlewareResult<Request, Response> {

        Log.info(request)
        return .Request(request)

    }

    static func logResponse<Response>(response: Response) -> Response {

        Log.info(response)
        return response
            
    }

}
