#!/bin/bash
/usr/lib/nagios/plugins/check_http -H localhost -p 8088 -u /svc_mon_introspect.xml 
