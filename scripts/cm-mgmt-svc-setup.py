from cm_api.api_client import ApiResource
from cm_api.endpoints.cms import ClouderaManager
from cm_api.endpoints.services import ApiServiceSetupInfo
from cm_api.endpoints.role_config_groups import get_role_config_group
import argparse


def create_mgmt_svc(cm_host, cm_port, cm_admin_password, amon_db_host, amon_db_password):
   api = ApiResource(cm_host, cm_port, "admin", cm_admin_password, version=7)
   cm = ClouderaManager(api)
   mgmt = cm.create_mgmt_service(ApiServiceSetupInfo())

   mgmt.create_role("SERVICEMONITOR-1",  "SERVICEMONITOR",   cm_host)
   mgmt.create_role("ACTIVITYMONITOR-1", "ACTIVITYMONITOR",  cm_host)
   mgmt.create_role("HOSTMONITOR-1",     "HOSTMONITOR",      cm_host)
   mgmt.create_role("EVENTSERVER-1",     "EVENTSERVER",      cm_host)
   mgmt.create_role("ALERTPUBLISHER-1",  "ALERTPUBLISHER",   cm_host)

   amon_role_config = {
      'firehose_database_host': amon_db_host,
      'firehose_database_type': 'mysql',
      'firehose_database_name': 'amon',
      'firehose_database_user': 'amon',
      'firehose_database_password': amon_db_password,
   }
   mgmt.get_role_config_group("mgmt-ACTIVITYMONITOR-BASE").update_config(amon_role_config)
   mgmt.start().wait()


if __name__== "__main__":
   parser = argparse.ArgumentParser(description='Script to create Cloudera Management Service')
   parser.add_argument('-c', action="store", dest="cm_host", help='CM host')
   parser.add_argument('-p', action="store", dest="cm_port", type=int, help='port of CM host')
   parser.add_argument('-a', action="store", dest="cm_admin_password", help='password of CM admin')
   parser.add_argument('-m', action="store", dest="amon_db_host", help='DB host of Activity Monitor')
   parser.add_argument('-w', action="store", dest="amon_db_password", help='DB password of Activity Monitor')
   args = parser.parse_args()
   create_mgmt_svc(args.cm_host, args.cm_port, args.cm_admin_password, args.amon_db_host, args.amon_db_password)
