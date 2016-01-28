//
//  FastCGI.swift
//  PerfectLib
//
//  Created by Kyle Jessup on 7/6/15.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU Affero General Public License as
//	published by the Free Software Foundation, either version 3 of the
//	License, or (at your option) any later version, as supplemented by the
//	Perfect Additional Terms.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU Affero General Public License, as supplemented by the
//	Perfect Additional Terms, for more details.
//
//	You should have received a copy of the GNU Affero General Public License
//	and the Perfect Additional Terms that immediately follow the terms and
//	conditions of the GNU Affero General Public License along with this
//	program. If not, see <http://www.perfect.org/AGPL_3_0_With_Perfect_Additional_Terms.txt>.
//

// values which are part of the FastCGI protocol but are unused in this implementation are commented out

#if os(Linux)
import SwiftGlibc
#endif

let fcgiVersion1: UInt8 =		1

let fcgiBeginRequest: UInt8 =		1
//let FCGI_ABORT_REQUEST: UInt8 =		2
let fcgiEndRequest: UInt8 =		3
let fcgiParams: UInt8 =			4
let fcgiStdin: UInt8 =				5
let fcgiStdout: UInt8 =			6
//let FCGI_STDERR: UInt8 =			7
let fcgiData: UInt8 =				8
//let FCGI_GET_VALUES: UInt8 =		9
//let FCGI_GET_VALUES_RESULT: UInt8 =	10
//let FCGI_UNKNOWN_TYPE: UInt8 =		11

let fcgiXStdin: UInt8 = 		50

//let FCGI_KEEP_CONN =	1

//let FCGI_RESPONDER =	1
//let FCGI_AUTHORIZE =	2
//let FCGI_FILTER =		3

let fcgiRequestComplete = 	0
//let FCGI_CANT_MPX_CONN =		1
//let FCGI_OVERLOADED =			2
//let FCGI_UNKNOWN_ROLE = 		3

//let FCGI_MAX_CONNS =	"FCGI_MAX_CONNS"
//let FCGI_MAX_REQS =		"FCGI_MAX_REQS"
//let FCGI_MPXS_CONNS =	"FCGI_MPXS_CONNS"

let fcgiTimeoutSeconds = 5.0
let fcgiBaseRecordSize = 8

let fcgiBodyChunkSize = 0xFFFF

class FastCGIRecord {
	
	var version: UInt8 = 0
	var recType: UInt8 = 0
	var requestId: UInt16 = 0
	var contentLength: UInt16 = 0
	var paddingLength: UInt8 = 0
	var reserved: UInt8 = 0
	
	var content: [UInt8]? = nil
	var padding: [UInt8]? = nil
	
}

class FastCGIRequest : WebConnection {
	
	var connection: NetTCP
	var requestId: UInt16 = 0
	var requestParams: Dictionary<String, String> = Dictionary<String, String>()
	var stdin: [UInt8]? = nil
	var mimes: MimeReader? = nil
	
	var statusCode: Int
	var statusMsg: String
	
	var header: String = ""
	var wroteHeader: Bool = false
	
	var lastRecordType: UInt8 = 0
	
	init(net: NetTCP) {
		connection = net
		statusCode = 200
		statusMsg = "OK"
	}
	
	func setStatus(code: Int, msg: String) {
		statusCode = code
		statusMsg = msg
	}
	
	func getStatus() -> (Int, String) {
		return (statusCode, statusMsg)
	}
	
	func putStdinData(b: [UInt8]) {
		if stdin == nil && mimes == nil {
			let contentType = requestParams["CONTENT_TYPE"]
			if contentType == nil || !contentType!.hasPrefix("multipart/form-data") {
				stdin = b
			} else {
				mimes = MimeReader(contentType!)//, Int(requestParams["CONTENT_LENGTH"] ?? "0")!)
				mimes!.addToBuffer(b)
			}
		} else if stdin != nil {
			stdin!.appendContentsOf(b)
		} else {
			mimes!.addToBuffer(b)
		}
	}
	
	func writeHeaderLine(h: String) {
		header += h + "\r\n"
	}
	
	func writeHeaderBytes(b: [UInt8]) {
		if !wroteHeader {
			wroteHeader = true
			
			let statusLine = "Status: \(statusCode) \(statusMsg)\r\n"
			let firstBytes = makeStdoutBody(Int(requestId), data: [UInt8](statusLine.utf8) + b)
			writeBytes(firstBytes)
			
		} else if b.count > 0 {
			let furtherBytes = makeStdoutBody(Int(requestId), data: b)
			writeBytes(furtherBytes)
		}
	}
	
	func writeBodyBytes(b: [UInt8]) {
		if !wroteHeader {
			header += "\r\n" // final CRLF
			writeHeaderBytes([UInt8](header.utf8))
			header = ""
		}
		let b = makeStdoutBody(Int(requestId), data: b)
		writeBytes(b)
	}
	
	func writeBytes(b: [UInt8]) {
		connection.writeBytesFully(b)
	}
	
	func makeEndRequestBody(requestId: Int, appStatus: Int, protocolStatus: Int) -> [UInt8] {
		
		let b = Bytes()
		b.import8Bits(fcgiVersion1)
			.import8Bits(fcgiEndRequest)
			.import16Bits(htons(UInt16(requestId)))
			.import16Bits(htons(UInt16(8)))
			.import8Bits(0)
			.import8Bits(0)
			.import32Bits(htonl(UInt32(appStatus)))
			.import8Bits(UInt8(protocolStatus))
			.import8Bits(0)
			.import8Bits(0)
			.import8Bits(0)
		
		return b.data
	}
	
	func makeStdoutBody(requestId: Int, data: [UInt8], firstPos: Int, count: Int) -> [UInt8] {
		let b = Bytes()
		
		if count > fcgiBodyChunkSize {
			b.importBytes(makeStdoutBody(requestId, data: data, firstPos: firstPos, count: fcgiBodyChunkSize))
			b.importBytes(makeStdoutBody(requestId, data: data, firstPos: fcgiBodyChunkSize + firstPos, count: count - fcgiBodyChunkSize))
		} else {
			
			let padBytes = count % 8
			b.import8Bits(fcgiVersion1)
				.import8Bits(fcgiStdout)
				.import16Bits(htons(UInt16(requestId)))
				.import16Bits(htons(UInt16(count)))
				.import8Bits(UInt8(padBytes))
				.import8Bits(0)
			if firstPos == 0 && count == data.count {
				b.importBytes(data)
			} else {
				b.importBytes(data[firstPos..<count])
			}
			if padBytes > 0 {
				for _ in 1...padBytes {
					b.import8Bits(0)
				}
			}
		}
		return b.data
	}
	
	func makeStdoutBody(requestId: Int, data: [UInt8]) -> [UInt8] {
		return makeStdoutBody(requestId, data: data, firstPos: 0, count: data.count)
	}
	
	func readRecord(continuation: (FastCGIRecord?) -> ()) {
		connection.readBytesFully(fcgiBaseRecordSize, timeoutSeconds: fcgiTimeoutSeconds) {
            [weak self] (b: [UInt8]?) -> () in
			
			guard let recBytes = b else {
				continuation(nil)
				return
			}
		
			let record = FastCGIRecord()
			record.version = recBytes[0]
			record.recType = recBytes[1]
			record.requestId = ntohs((UInt16(recBytes[3]) << 8) | UInt16(recBytes[2]))
			record.contentLength = ntohs((UInt16(recBytes[5]) << 8) | UInt16(recBytes[4]))
			record.paddingLength = recBytes[6];
			record.reserved = recBytes[7]
			
			self?.readRecordContent(record, continuation: continuation)
		}
	}
	
	func readRecordContent(record: FastCGIRecord, continuation: (FastCGIRecord?) -> ()) {
		if record.contentLength > 0 {
			
			connection.readBytesFully(Int(record.contentLength), timeoutSeconds: fcgiTimeoutSeconds, completion: {
				[weak self] (b:[UInt8]?) -> () in
				if let contentBytes = b {
					
					record.content = contentBytes
					self?.readRecordPadding(record, continuation: continuation)
					
				} else {
					continuation(nil)
				}
			})
			
		} else {
			readRecordPadding(record, continuation: continuation)
		}
	}
	
	func readRecordPadding(record: FastCGIRecord, continuation: (FastCGIRecord?) -> ()) {
		if record.paddingLength > 0 {
			
			connection.readBytesFully(Int(record.paddingLength), timeoutSeconds: fcgiTimeoutSeconds, completion: {
				(b:[UInt8]?) -> () in
				if let paddingBytes = b {
					
					record.padding = paddingBytes
					continuation(record)
					
				} else {
					continuation(nil)
				}
			})
			
		} else {
			continuation(record)
		}
	}
}





