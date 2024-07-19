#!/usr/bin/python3
# ^ this is called a shebang, with this you don't have to run your program with python3 fileName.py everytime, rather you run once:
# chmod +x fileName.py
# and then can just always run the file with:
# ./fileName.py

import sys
import psycopg2

"""
Q1. What is the difference between a connection and a cursor in Psycopg2? How do you create each?
"""
# A connection provides authenticated access to a database. You create a connection with:
conn = psycopg2.connect("dbname=mydb")

# A cursor provides a pipeline between the Python program and the PostgreSQL database. You create a cursor with:
cursor = conn.cursor()

# Those cursors can be used to send queries to the database and read back results as in:
cursor.execute("select * from Movies")
results = cursor.fetchall() # where results is a list of tuples.


"""
# Q2. What is the problem? And how can we fix it?
"""
# The scope of the conn object does not extend into the finally clause if conn is only initialised in the try clause. This is essentially what the error message is telling you: NameError: name 'conn' is not defined

# To fix the problem, you need to initialise conn in the outer scope. You can't simply move the connect() call there, because it would then be outside the try clause and the exception would be handled by the standard Python exception handler rather than our exception handler, e.g.
"""
Traceback (most recent call last):
  File "./opendb", line 9, in 
    conn = psycopg2.connect(f"dbname={db}")
  File "/Library/Frameworks/Python.framework/Versions/3.7/lib/python3.7/site-packages/psycopg2/__init__.py", line 127, in connect
    conn = _connect(dsn, connection_factory=connection_factory, **kwasync)
psycopg2.OperationalError: FATAL:  database "nonexistent" does not exist
"""

# The solution is to initialise conn outside the try clause:
db = sys.argv[1]
conn = None  # <-- ADD THIS
try:
    conn = psycopg2.connect(f"dbname={db}")
    print(conn)
    cur = conn.cursor()
except psycopg2.Error as err:
    print("database error: ", err)
finally:
    if conn is not None:
        conn.close()
    print("finished with the database")
