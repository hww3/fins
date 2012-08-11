inherit .Personality;

mapping dbtype_to_finstype =
([
    "char": "string",
    "nchar": "string",
    "varchar": "string",
    "nvarchar": "string",
    "varchar2": "string",
    "nvarchar2": "string",
    "number": "number",
    "date": "date",
    "timestamp": "timestamp",
    "blob": "binary_string",
    "clob": "string",
    "nclob": "string"
]);

