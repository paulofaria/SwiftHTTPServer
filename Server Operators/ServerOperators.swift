// ServerOperators.swift
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

infix operator >>> { associativity left }

func >>><A, B, C>(f: (A -> B), g: (B -> C)) -> (A -> C) {

    return { x in g(f(x)) }

}

func >>><A, B, C>(f: (A throws -> B), g: (B throws -> C)) -> (A throws -> C) {

    return { x in try g(f(x)) }

}

func >>><Request, Response>(respond: (Request -> Response), middleware: (Request -> Response) -> (Request -> Response)) -> (Request -> Response) {

    return middleware(respond)

}

func >>><Request, Response>(respond: (Request -> Response), middleware: ((Request, Response) -> Void)) -> (Request -> Response) {

    return { request in

        let response = respond(request)
        middleware(request, response)
        return response
        
    }
    
}

func >>><Request, Response, T: Respondable where T.Request == Request, T.Response == Response>(responder: T, middleware: ((Request, Response) -> Void)) -> (Request throws -> Response) {

    return { request in

        let response = try responder.respond(request)
        middleware(request, response)
        return response

    }
    
}

func >>><Request, Response>(respond: (Request throws -> Response), middleware: ((Request, Response) -> Void)) -> (Request throws -> Response) {

    return { request in

        let response = try respond(request)
        middleware(request, response)
        return response
        
    }
    
}

func >>><Request, Response>(respond: Request throws -> Response, respondError: ErrorType -> Response) -> (Request -> Response) {

    return { request in

        do {

            return try respond(request)

        } catch {

            return respondError(error)
            
        }
        
    }
    
}

func >>><Request, Response, T: Respondable where T.Request == Request, T.Response == Response>(responder: T, respondError: ErrorType -> Response) -> (Request -> Response) {

    return { request in

        do {

            return try responder.respond(request)

        } catch {

            return respondError(error)
            
        }
        
    }
    
}

func ??<Request, Response>(respondA: (Request throws -> Response)?, respondB: Request throws -> Response) -> (Request throws -> Response) {

    if let respondA = respondA {

        return respondA

    }

    return respondB
    
}