//
//  PostgreSQLSwifInterfaceTests.swift
//  PostgreSQL
//
//  Created by Lucas Goossen on 1/21/16.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

import XCTest
@testable import PostgreSQL

class PostgreSQLSwifInterfaceTests: XCTestCase {
	let p = PGConnection()
	override func setUp() {
		super.setUp()
		var status = p.connectToDB("postgres")
		XCTAssert(status == .OK)

		var result = p.exec("CREATE DATABASE testdb;")
		XCTAssertEqual("", result.errorMessage())
		p.close()

		status = p.connectToDB("testdb")
		XCTAssert(status == .OK)
		
		result = p.exec("CREATE EXTENSION citext;")
		XCTAssertEqual("", result.errorMessage())

	}
	
	override func tearDown() {
		p.close()
		let status = p.connectToDB("postgres")
		XCTAssert(status == .OK)

		let result = p.exec("DROP DATABASE testdb")
		XCTAssertEqual("", result.errorMessage())
		super.tearDown()
	}
	
	func testCreateTable(){
		var result = p.createTable("createtabletest", columnsAndTypes: ["columnname1":"int", "columnname2":"citext", "columnname3":"text"])
		XCTAssertEqual("", result.errorMessage())

		result = p.exec("INSERT INTO createtabletest VALUES (50, 0.25, 'test');")
		XCTAssertEqual("", result.errorMessage())
	}
	
	func testInsert(){
		var result = p.createTable("createtabletest", columnsAndTypes: ["testname":"varchar(10)", "columnname2":"real", "columnname3":"int"])
		XCTAssertEqual("", result.errorMessage())

		result =  p.insert([("testname","testvalue"), ("columnname2","0.25"),  ("columnname3","\(1)")], intoTable:"createtabletest")
		XCTAssertEqual("", result.errorMessage())
	}
	
	func testSearchColumnBeginsWith(){
		var result = p.createTable("test", columnsAndTypes: ["test":"text", "test2":"int"])
		XCTAssertEqual("", result.errorMessage())
		
		result = p.insert([("test", "test")], intoTable: "test")
		XCTAssertEqual("", result.errorMessage())
		result = p.insert([("test", "1testing")], intoTable: "test")
		XCTAssertEqual("", result.errorMessage())
		result = p.insert([("test", "2testin")], intoTable: "test")
		XCTAssertEqual("", result.errorMessage())
		result = p.insert([("test", "3testing1")], intoTable: "test")
		XCTAssertEqual("", result.errorMessage())
		
		let searchResult =  p.searchColumn("test", fromTable: "test", forResultThatBiginsWith: "te")
		XCTAssertEqual("test", searchResult?[0])
		
		XCTAssert(searchResult?.count == 1)
	}
	
	func testSearchColumnContains(){
		var result = p.createTable("test", columnsAndTypes: ["test":"text", "test2":"int"])
		XCTAssertEqual("", result.errorMessage())
		
		result = p.insert([("test", "test")], intoTable: "test")
		XCTAssertEqual("", result.errorMessage())
		result = p.insert([("test", "1testing")], intoTable: "test")
		XCTAssertEqual("", result.errorMessage())
		result = p.insert([("test", "2testin")], intoTable: "test")
		XCTAssertEqual("", result.errorMessage())
		result = p.insert([("test", "3testing1")], intoTable: "test")
		XCTAssertEqual("", result.errorMessage())
		
		let searchResult =  p.searchColumn("test", fromTable: "test", forResultsThatContain: "te")
		XCTAssertEqual("test", searchResult?[0])
		
		XCTAssert(searchResult?.count == 4)
	}

	func testUpdateTable(){
		var result = p.createTable("test", columnsAndTypes: ["test":"text", "test1":"text", "test2":"text", "test3":"text",])
		XCTAssertEqual("", result.errorMessage())
		
		result = p.insert([("test", "test"), ("test2","2")], intoTable: "test")
		XCTAssertEqual("", result.errorMessage())
		result = p.insert([("test1", "1testing")], intoTable: "test")
		XCTAssertEqual("", result.errorMessage())
		result = p.insert([("test2", "2testin")], intoTable: "test")
		XCTAssertEqual("", result.errorMessage())
		result = p.insert([("test3", "3testing1")], intoTable: "test")
		XCTAssertEqual("", result.errorMessage())
		
		result = p.updateTable("test", whereColumn: "test", isNamed: "test", keysAndValues: [("test","5test")])
		XCTAssertEqual("", result.errorMessage())

		
		//
				var searchResult =  p.searchColumn("test", fromTable: "test", forResultsThatContain: "5")
				XCTAssertEqual("5test", searchResult?[0])
		
		searchResult = p.searchColumn("test", fromTable: "test", forResultThatBiginsWith: "5")
		XCTAssert(searchResult?.count == 1)
		
		//XCTAssert(searchResult?.count == 4)
	}
}

