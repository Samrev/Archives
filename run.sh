#!/bin/bash

export FLASK_APP=FRONT_END/LoanManagementSystem.py
export FLASK_ENV=development
export FLASK_DEBUG=1

flask run --port=5023

