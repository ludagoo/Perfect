//
//  BSON.swift
//  BSON
//
//  Created by Kyle Jessup on 2015-11-18.
//  Copyright © 2015 PerfectlySoft. All rights reserved.
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

import libmongoc

public enum BSONError: ErrorType {
	/// The JSON data was malformed.
	case SyntaxError(String)
}

public class BSON: CustomStringConvertible {
	var doc: UnsafeMutablePointer<bson_t>

	public var description: String {
		return asString
	}

	public init() {
		doc = bson_new()
	}

	public init(bytes: [UInt8]) {
		doc = bson_new_from_data(bytes, bytes.count)
	}

	public init(json: String) throws {
		var error = bson_error_t()
		doc = bson_new_from_json(json, json.utf8.count, &error)
		if doc == nil {
			let message = withUnsafePointer(&error.message) {
				String.fromCString(UnsafePointer($0))!
			}
			throw BSONError.SyntaxError(message)
		}
	}

	public init(document: BSON) {
		doc = bson_copy(document.doc)
	}

	init(rawBson: UnsafeMutablePointer<bson_t>) {
		doc = rawBson
	}

	public func close() {
		if doc != nil {
			bson_destroy(doc)
			doc = nil
		}
	}

	public var asString: String {
		var length = 0
		let data = bson_as_json(doc, &length)
		defer {
			bson_free(data)
		}
		return String.fromCString(data)!
	}

	public var asArrayString: String {
		var length = 0
		let data = bson_array_as_json(doc, &length)
		defer {
			bson_free(data)
		}
		return String.fromCString(data)!
	}

	public var asBytes: [UInt8] {
		let length = Int(doc.memory.len)
		let data = bson_get_data(doc)
		var ret = [UInt8]()
		for i in 0..<length {
			ret.append(data[i])
		}
		return ret
	}

	public func append(key: String, document: BSON) -> Bool {
		return bson_append_document(doc, key, -1, document.doc)
	}

	public func append(key: String) -> Bool {
		return bson_append_null(doc, key, -1)
	}

	public func append(key: String, oid: bson_oid_t) -> Bool {
		var cpy = oid
		return bson_append_oid(doc, key, -1, &cpy)
	}

	public func append(key: String, int: Int) -> Bool {
		return bson_append_int64(doc, key, -1, Int64(int))
	}

	public func append(key: String, int32: Int32) -> Bool {
		return bson_append_int32(doc, key, -1, int32)
	}

	public func append(key: String, dateTime: Int64) -> Bool {
		return bson_append_date_time(doc, key, -1, dateTime)
	}

	public func append(key: String, time: time_t) -> Bool {
		return bson_append_time_t(doc, key, -1, time)
	}

	public func append(key: String, double: Double) -> Bool {
		return bson_append_double(doc, key, -1, double)
	}

	public func append(key: String, bool: Bool) -> Bool {
		return bson_append_bool(doc, key, -1, bool)
	}

	public func append(key: String, string: String) -> Bool {
		return bson_append_utf8(doc, key, -1, string, -1)
	}

	public func append(key: String, bytes: [UInt8]) -> Bool {
		return bson_append_binary(doc, key, -1, BSON_SUBTYPE_BINARY, bytes, UInt32(bytes.count))
	}

	public func append(key: String, regex: String, options: String) -> Bool {
		return bson_append_regex(doc, key, -1, regex, options)
	}

	public func countKeys() -> Int {
		return Int(bson_count_keys(doc))
	}

	public func hasField(key: String) -> Bool {
		return bson_has_field(doc, key)
	}

	public func appendArrayBegin(key: String, child: BSON) -> Bool {
		return bson_append_array_begin(doc, key, -1, child.doc)
	}

	public func appendArrayEnd(child: BSON) -> Bool {
		return bson_append_array_end(doc, child.doc)
	}

	public func appendArray(key: String, array: BSON) -> Bool {
		return bson_append_array(doc, key, -1, array.doc)
	}

	public func concat(src: BSON) -> Bool {
		return bson_concat(doc, src.doc)
	}
}

public func ==(lhs: BSON, rhs: BSON) -> Bool {
	let cmp = bson_compare(lhs.doc, rhs.doc)
	return cmp == 0
}

public func <(lhs: BSON, rhs: BSON) -> Bool {
	let cmp = bson_compare(lhs.doc, rhs.doc)
	return cmp < 0
}

extension BSON: Comparable {}

class NoDestroyBSON: BSON {

	override func close() {
		doc = nil
	}

}
