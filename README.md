# joplin-emelz
K8s Configuration for joplin-emelz

# Local setup
## tldr;
```bash
make k3d
curl http://localhost:22300/api/ping
make destroy-k3d
```
Navigate to [http://localhost:22300](http://localhost:22300)
![Jopling login](<images/Joplin login.png>)

## Example
(expandable) 

### terminal 1:
Start the server
```bash
ericmelz@homer joplin-emelz % make k3d
bash scripts/k3d.sh
CLUSTER_NAME=joplin
Creating cluster 'joplin' using project-specific config...
INFO[0000] portmapping '22300:22300' targets the loadbalancer: defaulting to [servers:*:proxy agents:*:proxy] 
INFO[0000] Prep: Network                                
INFO[0000] Created network 'k3d-joplin'                 
INFO[0000] Created image volume k3d-joplin-images       
INFO[0000] Starting new tools node...                   
INFO[0000] Starting node 'k3d-joplin-tools'             
INFO[0001] Creating node 'k3d-joplin-server-0'          
INFO[0001] Creating LoadBalancer 'k3d-joplin-serverlb'  
INFO[0001] Using the k3d-tools node to gather environment information 
INFO[0001] Starting new tools node...                   
INFO[0001] Starting node 'k3d-joplin-tools'             
INFO[0002] Starting cluster 'joplin'                    
INFO[0002] Starting servers...                          
INFO[0002] Starting node 'k3d-joplin-server-0'          
INFO[0004] All agents already running.                  
INFO[0004] Starting helpers...                          
INFO[0004] Starting node 'k3d-joplin-serverlb'          
INFO[0010] Injecting records for hostAliases (incl. host.k3d.internal) and for 3 network members into CoreDNS configmap... 
INFO[0012] Cluster 'joplin' created successfully!       
INFO[0012] You can now use it like this:                
kubectl cluster-info
Deploying resources to k3d...
Release "joplin-emelz" does not exist. Installing it now.
NAME: joplin-emelz
LAST DEPLOYED: Mon Sep 29 10:39:32 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
ericmelz@homer joplin-emelz % kubectl get po
NAME                            READY   STATUS    RESTARTS   AGE
joplin-emelz-5ff955487d-b5ztp   0/1     Pending   0          4s
ericmelz@homer joplin-emelz % kubectl describe po joplin-emelz-5ff955487d-b5ztp
Name:             joplin-emelz-5ff955487d-b5ztp
Namespace:        default
Priority:         0
Service Account:  default
Node:             k3d-joplin-server-0/172.18.0.3
Start Time:       Mon, 29 Sep 2025 10:39:46 -0700
Labels:           app=joplin-emelz
                  pod-template-hash=5ff955487d
Annotations:      <none>
Status:           Pending
IP:               
IPs:              <none>
Controlled By:    ReplicaSet/joplin-emelz-5ff955487d
Containers:
  joplin:
    Container ID:   
    Image:          joplin/server:latest
    Image ID:       
    Port:           22300/TCP
    Host Port:      0/TCP
    State:          Waiting
      Reason:       ContainerCreating
    Ready:          False
    Restart Count:  0
    Environment:
      APP_PORT:           22300
      APP_BASE_URL:       http://localhost:22300
      DB_CLIENT:          pg
      POSTGRES_HOST:      100.102.105.59
      POSTGRES_PORT:      55434
      POSTGRES_DATABASE:  joplin
      POSTGRES_USER:      joplin
      JWT_SECRET_FILE:    /run/secrets/jwt_secret
      POSTGRES_PASSWORD:  <set to the key 'POSTGRES_PASSWORD' in secret 'joplin-emelz-secret'>  Optional: false
    Mounts:
      /home/joplin/.joplin from joplin-emelz-joplin (rw)
      /run/secrets/jwt_secret from joplin-emelz-jwt-secret (ro)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-lggrj (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   False 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  joplin-emelz-joplin:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  pvc-joplin-emelz-joplin
    ReadOnly:   false
  joplin-emelz-jwt-secret:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  pvc-joplin-emelz-jwt-secret
    ReadOnly:   false
  kube-api-access-lggrj:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  28s   default-scheduler  0/1 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling.
  Warning  FailedScheduling  16s   default-scheduler  0/1 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling.
  Normal   Scheduled         14s   default-scheduler  Successfully assigned default/joplin-emelz-5ff955487d-b5ztp to k3d-joplin-server-0
  Normal   Pulling           14s   kubelet            Pulling image "joplin/server:latest"
ericmelz@homer joplin-emelz % 
ericmelz@homer joplin-emelz % 
ericmelz@homer joplin-emelz % kubectl get po
NAME                            READY   STATUS              RESTARTS   AGE
joplin-emelz-5ff955487d-b5ztp   0/1     ContainerCreating   0          40s
ericmelz@homer joplin-emelz % kubectl get po
NAME                            READY   STATUS    RESTARTS   AGE
joplin-emelz-5ff955487d-b5ztp   1/1     Running   0          60s
ericmelz@homer joplin-emelz % kubectl logs -f deployment/joplin-emelz
yarn run v1.22.22
$ pm2 kill && pm2 start --no-daemon --exp-backoff-restart-delay=1000 dist/app.js
[PM2] Spawning PM2 daemon with pm2_home=/opt/pm2
[PM2] PM2 Successfully daemonized
[PM2][Module] Starting NPM module pm2-logrotate
[PM2][WARN] Applications pm2-logrotate not running, starting...
[PM2] App [pm2-logrotate] launched (1 instances)
[PM2] Applying action deleteProcessId on app [all](ids: [ 0 ])
[PM2] [pm2-logrotate](0) ✓
[PM2] [v] All Applications Stopped
[PM2] [v] PM2 Daemon Stopped
pm2 launched in no-daemon mode (you can add DEBUG="*" env variable to get more messages)
2025-09-29T17:40:19: PM2 log: Launching in no daemon mode
2025-09-29T17:40:19: PM2 log: [PM2][Module] Starting NPM module pm2-logrotate
2025-09-29T17:40:19: PM2 log: [PM2][WARN] Applications pm2-logrotate not running, starting...
2025-09-29T17:40:19: PM2 log: App [pm2-logrotate:0] starting in -fork mode-
2025-09-29T17:40:19: PM2 log: App [pm2-logrotate:0] online
2025-09-29T17:40:19: PM2 log: [PM2] App [pm2-logrotate] launched (1 instances)
2025-09-29T17:40:19: PM2 log: [PM2] Starting /home/joplin/packages/server/dist/app.js in fork_mode (1 instance)
2025-09-29T17:40:19: PM2 log: App [app:1] starting in -fork mode-
2025-09-29T17:40:19: PM2 log: App [app:1] online
2025-09-29T17:40:19: PM2 log: [PM2] Done.
2025-09-29T17:40:19: PM2 log: ┌────┬──────────────────┬─────────────┬─────────┬─────────┬──────────┬────────┬──────┬───────────┬──────────┬──────────┬──────────┬──────────┐
│ id │ name             │ namespace   │ version │ mode    │ pid      │ uptime │ ↺    │ status    │ cpu      │ mem      │ user     │ watching │
├────┼──────────────────┼─────────────┼─────────┼─────────┼──────────┼────────┼──────┼───────────┼──────────┼──────────┼──────────┼──────────┤
│ 1  │ app              │ default     │ 3.4.3   │ fork    │ 81       │ 0s     │ 0    │ online    │ 0%       │ 25.7mb   │ joplin   │ disabled │
└────┴──────────────────┴─────────────┴─────────┴─────────┴──────────┴────────┴──────┴───────────┴──────────┴──────────┴──────────┴──────────┘
2025-09-29T17:40:19: PM2 log: Module
2025-09-29T17:40:19: PM2 log: ┌────┬──────────────────────────────┬───────────────┬──────────┬──────────┬──────┬──────────┬──────────┬──────────┐
│ id │ module                       │ version       │ pid      │ status   │ ↺    │ cpu      │ mem      │ user     │
├────┼──────────────────────────────┼───────────────┼──────────┼──────────┼──────┼──────────┼──────────┼──────────┤
│ 0  │ pm2-logrotate                │ 3.0.0         │ 70       │ online   │ 0    │ 100%     │ 39.9mb   │ joplin   │
└────┴──────────────────────────────┴───────────────┴──────────┴──────────┴──────┴──────────┴──────────┴──────────┘
2025-09-29T17:40:19: PM2 log: [--no-daemon] Continue to stream logs
2025-09-29T17:40:19: PM2 log: [--no-daemon] Exit on target PM2 exit pid=59
17:40:19 1|app  | 2025-09-29 17:40:19: App: Starting server v3.4.3 (prod) on port 22300 and PID 81...
17:40:19 1|app  | 2025-09-29 17:40:19: App: Checking for time drift using NTP server: pool.ntp.org:123
17:40:20 1|app  | 2025-09-29 17:40:20: App: NTP time offset: -41ms
17:40:20 1|app  | 2025-09-29 17:40:20: App: Running in Docker: true
17:40:20 1|app  | 2025-09-29 17:40:20: App: Public base URL: http://localhost:22300
17:40:20 1|app  | 2025-09-29 17:40:20: App: API base URL: http://localhost:22300
17:40:20 1|app  | 2025-09-29 17:40:20: App: User content base URL: http://localhost:22300
17:40:20 1|app  | 2025-09-29 17:40:20: App: Log dir: /home/joplin/packages/server/logs
17:40:20 1|app  | 2025-09-29 17:40:20: App: DB Config: {
17:40:20 1|app  |   client: 'pg',
17:40:20 1|app  |   name: 'joplin',
17:40:20 1|app  |   slowQueryLogEnabled: false,
17:40:20 1|app  |   slowQueryLogMinDuration: 1000,
17:40:20 1|app  |   autoMigration: true,
17:40:20 1|app  |   user: 'joplin',
17:40:20 1|app  |   password: '********',
17:40:20 1|app  |   port: 55434,
17:40:20 1|app  |   host: '100.102.105.59'
17:40:20 1|app  | }
17:40:20 1|app  | 2025-09-29 17:40:20: App: Mailer Config: {
17:40:20 1|app  |   enabled: false,
17:40:20 1|app  |   host: '',
17:40:20 1|app  |   port: 465,
17:40:20 1|app  |   security: 'tls',
17:40:20 1|app  |   authUser: '',
17:40:20 1|app  |   authPassword: '********',
17:40:20 1|app  |   noReplyName: '',
17:40:20 1|app  |   noReplyEmail: ''
17:40:20 1|app  | }
17:40:20 1|app  | 2025-09-29 17:40:20: App: Content driver: { type: 1 }
17:40:20 1|app  | 2025-09-29 17:40:20: App: Content driver (fallback): null
17:40:20 1|app  | 2025-09-29 17:40:20: App: Trying to connect to database...
17:40:20 1|app  | 2025-09-29 17:40:20: App: Connection check: {
17:40:20 1|app  |   latestMigration: { name: '20250720103211_fix_sso_auth_code_expire_at.js', done: true },
17:40:20 1|app  |   isCreated: true,
17:40:20 1|app  |   error: null
17:40:20 1|app  | }
17:40:20 1|app  | 2025-09-29 17:40:20: App: Auto-migrating database...
17:40:20 1|app  | 2025-09-29 17:40:20: App: Latest migration: { name: '20250720103211_fix_sso_auth_code_expire_at.js', done: true }
17:40:20 1|app  | 2025-09-29 17:40:20: App: Not using database replication...
17:40:20 1|app  | 2025-09-29 17:40:20: EmailService: Service will be disabled because mailer config is not set or is explicitly disabled
17:40:20 1|app  | 2025-09-29 17:40:20: App: Performing main storage check...
17:40:20 1|app  | 2025-09-29 17:40:20: App: Database storage is special and cannot be checked this way. If the connection to the database was successful then the storage driver should work too.
17:40:20 1|app  | 2025-09-29 17:40:20: App: Starting services...
17:40:20 1|app  | 2025-09-29 17:40:20: TaskService: Scheduling #1 (Delete expired tokens): 0 */6 * * *
17:40:20 1|app  | 2025-09-29 17:40:20: TaskService: Scheduling #2 (Update total sizes): 0 * * * *
17:40:20 1|app  | 2025-09-29 17:40:20: TaskService: Scheduling #3 (Process oversized accounts): 30 */2 * * *
17:40:20 1|app  | 2025-09-29 17:40:20: TaskService: Scheduling #6 (Delete expired sessions): 0 */6 * * *
17:40:20 1|app  | 2025-09-29 17:40:20: TaskService: Scheduling #7 (Compress old changes): 0 0 */2 * *
17:40:20 1|app  | 2025-09-29 17:40:20: TaskService: Scheduling #8 (Process user deletions): 10 * * * *
17:40:20 1|app  | 2025-09-29 17:40:20: TaskService: Scheduling #10 (Process orphaned items): 15 * * * *
17:40:20 1|app  | 2025-09-29 17:40:20: TaskService: Scheduling #11 (Process shared items): PT10S
17:40:20 1|app  | 2025-09-29 17:40:20: TaskService: Scheduling #12 (Process emails): * * * * *
17:40:20 1|app  | 2025-09-29 17:40:20: TaskService: Scheduling #13 (Log heartbeat message): * * * * *
17:40:20 1|app  | 2025-09-29 17:40:20: TaskService: Scheduling #15 (Delete expired authentication codes): */15 * * * *
```

### terminal 2:
Ping the server
```bash
ericmelz@homer joplin-emelz % curl http://localhost:22300/api/ping
{"status":"ok","message":"Joplin Server is running"}%    
```

### terminal 1:
Kill the log tailing and destroy the cluster:
```
^C
                                                                                                                     ericmelz@homer joplin-emelz % make destroy-k3d
bash scripts/destroy-k3d.sh
INFO[0000] Deleting cluster 'joplin'                    
INFO[0002] Deleting cluster network 'k3d-joplin'        
INFO[0002] Deleting 1 attached volumes...               
INFO[0002] Removing cluster details from default kubeconfig... 
INFO[0002] Removing standalone kubeconfig file (if there is one)... 
INFO[0002] Successfully deleted cluster joplin!         
```

# Prod setup
TBD

