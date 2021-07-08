#!/bin/bash

blaze test third_party/dart_src/angular/goldens:all --test_arg=--update --test_strategy=local --nocache_test_results
