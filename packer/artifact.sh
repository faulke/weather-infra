#!/usr/bin/env bash
curl.exe -O --user $1:$2 $3/httpAuth/app/rest/builds/buildType:Weatherapp_Build,branch:$4/artifacts/content/weather-$4.zip
