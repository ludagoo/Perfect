//
//  PostgreSQLSwifInterface.swift
//  
//
//  Created by Lucas Goossen on 1/21/16.
//
//

import Foundation
import libpq

extension PGConnection {
	
	public func connectToDB(name: String) -> PostgreSQL.PGConnection.StatusType{
		conn = PQconnectdb("dbname = \(name)")
		return status()
	}

	public func createTable(name: String, columnsAndTypes: [String:String]) -> PGResult{
		var statment = "CREATE TABLE " + name + "("
		
		for (column, valueType) in columnsAndTypes{
			statment = statment + column + " " + valueType + ","
		}
		statment = statment.substringToIndex(statment.endIndex.predecessor()) + ");"
		
		return exec(statment)
	}
	
	public func insert(columnNamesAndValues:[(String,String)], intoTable name:String) -> PGResult{
		var statment = ""
		if !columnNamesAndValues.isEmpty {
			statment = "INSERT INTO " + name + "("
			var columns = ""
			var values = ""
			for (column, value) in columnNamesAndValues{
				columns = columns + column + ", "
				values = values + "'" + value + "'" + ", "
			}
			statment = statment + columns.substringToIndex(columns.endIndex.predecessor().predecessor()) + ") VALUES ("
			statment = statment + values.substringToIndex(values.endIndex.predecessor().predecessor()) + ");"
		}
		print(statment)
		print("!!!")
		return exec(statment)
	}
	
	public func searchColumn(column:String, fromTable table:String, forResultThatBiginsWith term:String) -> [String]? {

		let statment = "SELECT " + column + " FROM " + table + " WHERE " + column + " LIKE '" + term + "%';"
		
		let result = exec(statment)
		var resultArray:[String]? = nil
		if result.status() == PGResult.StatusType.TuplesOK && result.numTuples() > 0{
			resultArray = []
			for tupleIndex in 0...result.numTuples() - 1{
				resultArray?.append(result.getFieldString(tupleIndex, fieldIndex: 0))
			}
		}
		return resultArray
	}
	
	public func searchColumn(column:String, fromTable table:String, forResultsThatContain term:String) -> [String]? {
	
		let statment = "SELECT " + column + " FROM " + table + " WHERE " + column + " LIKE '%" + term + "%';"

		let result = exec(statment)
		var resultArray:[String]? = nil
		if result.status() == PGResult.StatusType.TuplesOK && result.numTuples() > 0{
			resultArray = []
			for tupleIndex in 0...result.numTuples() - 1{
				resultArray?.append(result.getFieldString(tupleIndex, fieldIndex: 0))
			}
		}
		return resultArray
	}
	
	public func updateTable(table:String, whereColumn column:String, isNamed name:String, keysAndValues:[(String,String)]) -> PGResult {
		var statment = "UPDATE weather SET temp_hi = temp_hi - 2,  temp_lo = temp_lo - 2 WHERE date > '1994-11-28';"
		
		statment = "UPDATE " + table + " SET "
		
		for (key, value) in keysAndValues {
			statment = statment + key + " = '" + value + "', "
		}
		
		statment = statment.substringToIndex(statment.endIndex.predecessor().predecessor()) + " WHERE " + column + " = '" + name + "';"
		
		return exec(statment)
	}
	
}


/*
extension PGResult{
	public func swiftType<T>(index: Int)->T{
		if let type = fieldType(index) {
		switch(type){
		case 16: //BOOLOID
				return getFieldBool(0, fieldIndex: index)
			//return String
		}
		
		}
	}
}

public enum PGType:Oid {
	case BOOLOID = 16
	case BYTEAOID = 17
	case CHAROID = 18
	case NAMEOID = 19
	case INT8OID = 20
	case INT2OID = 21
	case INT2VECTOROID = 22
	case INT4OID = 23
	case REGPROCOID = 24
	case TEXTOID = 25
	case OIDOID	= 26
	case TIDOID = 27
	case XIDOID = 28
	case CIDOID = 29
	case OIDVECTOROID = 30
	case POINTOID = 600
	case LSEGOID = 601
	case PATHOID = 602
	case BOXOID = 603
	case POLYGONOID = 604
	case LINEOID = 628
	case FLOAT4OID = 700
	case FLOAT8OID = 701
	case ABSTIMEOID = 702
	case RELTIMEOID = 703
	case TINTERVALOID = 704
	case UNKNOWNOID = 705
	case CIRCLEOID = 718
	case CASHOID = 790
	case INETOID = 869
	case CIDROID = 650
	case BPCHAROID = 1042
	case VARCHAROID = 1043
	case DATEOID = 1082
	case TIMEOID = 1083
	case TIMESTAMPOID = 1114
	case TIMESTAMPTZOID = 1184
	case INTERVALOID = 1186
	case TIMETZOID = 1266
	case ZPBITOID = 1560
	case VARBITOID = 1562
	case NUMERICOID = 1700

}
*/
