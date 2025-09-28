Script started on Sun Sep 28 13:04:50 2025
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004hsscripts/s k3d.sh[1m [0m[0m [?2004l
CLUSTER_NAME=dev
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004hmmake k3d[?2004l
bash scripts/k3d.sh
CLUSTER_NAME=dev
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004hggit statu[9D         [9D
bck-i-search: _[K[A[15Cscri[4mp[24mts/k3d.sh[1B[30Dp_[A[18Cgit [24madd *;git commit -m"work";git [4mpu[24msh[1B[53Du_[A[47C[1C[4mu[4ms[24m[1B[51Ds_[A[46C[24mp[24mu[24ms[1B[K[A[64C[?2004l[1BThe following paths are ignored by one of your .gitignore files:
Makefile~
[33mhint: Use -f if you really want to add them.[m
[33mhint: Turn this message off by running[m
[33mhint: "git config advice.addIgnoredFile false"[m
[main 397a4d7] work
 2 files changed, 9 insertions(+)
 create mode 100644 Makefile
 create mode 100644 k3d.sh
Enumerating objects: 5, done.
Counting objects:  20% (1/5)Counting objects:  40% (2/5)Counting objects:  60% (3/5)Counting objects:  80% (4/5)Counting objects: 100% (5/5)Counting objects: 100% (5/5), done.
Delta compression using up to 14 threads
Compressing objects:  33% (1/3)Compressing objects:  66% (2/3)Compressing objects: 100% (3/3)Compressing objects: 100% (3/3), done.
Writing objects:  25% (1/4)Writing objects:  50% (2/4)Writing objects:  75% (3/4)Writing objects: 100% (4/4)Writing objects: 100% (4/4), 636 bytes | 636.00 KiB/s, done.
Total 4 (delta 0), reused 0 (delta 0), pack-reused 0
To github.com:ericmelz/joplin-emelz.git
   f8ce4d5..397a4d7  main -> main
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004hkk3d[?2004l
Usage:
  k3d [flags]
  k3d [command]

Available Commands:
  cluster      Manage cluster(s)
  completion   Generate completion scripts for [bash, zsh, fish, powershell | psh]
  config       Work with config file(s)
  help         Help about any command
  image        Handle container images.
  kubeconfig   Manage kubeconfig(s)
  node         Manage node(s)
  registry     Manage registry/registries
  version      Show k3d and default k3s version

Flags:
  -h, --help         help for k3d
      --timestamps   Enable Log timestamps
      --trace        Enable super verbose output (trace logging)
      --verbose      Enable verbose output (debug logging)
      --version      Show k3d and default k3s version

Use "k3d [command] --help" for more information about a command.
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004h[?2004l
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004h[?2004l
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004h
bck-i-search: _[K[A[15Cgit add *;git commit -[4mm[24m"work";git push[1B[54Dm_[A[36C[22D[4mm[4ma[24mke k3d              [24m                [1B[53Da_[A[13C[4mm[4ma[4mk[24m[1B[17Dk_[A[12C[24mm[24ma[24mk[1B[K[A[30C[?2004l[1Bbash scripts/k3d.sh
CLUSTER_NAME=dev
scripts/k3d.sh: line 11: CLUSTER_LIST: unbound variable
Creating cluster 'dev' using project-specific config...
[36mINFO[0m[0000] portmapping '8880:80' targets the loadbalancer: defaulting to [servers:*:proxy agents:*:proxy] 
[31mERRO[0m[0000] Failed to get nodes for cluster 'dev': docker failed to get containers with labels 'map[k3d.cluster:dev]': failed to list containers: Cannot connect to the Docker daemon at unix:///Users/ericmelz/.docker/run/docker.sock. Is the docker daemon running? 
[36mINFO[0m[0000] Prep: Network                                
[31mERRO[0m[0000] Failed Cluster Preparation: Failed Network Preparation: failed to create cluster network: failed to check for duplicate docker networks: docker failed to list networks: Cannot connect to the Docker daemon at unix:///Users/ericmelz/.docker/run/docker.sock. Is the docker daemon running? 
[31mERRO[0m[0000] Failed to create cluster >>> Rolling Back    
[36mINFO[0m[0000] Deleting cluster 'dev'                       
[31mERRO[0m[0000] Failed to get nodes for cluster 'dev': docker failed to get containers with labels 'map[k3d.cluster:dev]': failed to list containers: Cannot connect to the Docker daemon at unix:///Users/ericmelz/.docker/run/docker.sock. Is the docker daemon running? 
[31mERRO[0m[0000] failed to get cluster: No nodes found for given cluster 
[31mFATA[0m[0000] Cluster creation FAILED, also FAILED to rollback changes! 
make: *** [k3d] Error 1
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004hmake k3d[?2004l
bash scripts/k3d.sh
CLUSTER_NAME=dev
scripts/k3d.sh: line 11: CLUSTER_LIST: unbound variable
Creating cluster 'dev' using project-specific config...
[36mINFO[0m[0000] portmapping '8880:80' targets the loadbalancer: defaulting to [servers:*:proxy agents:*:proxy] 
[36mINFO[0m[0000] Prep: Network                                
[36mINFO[0m[0000] Created network 'k3d-dev'                    
[36mINFO[0m[0000] Created image volume k3d-dev-images          
[36mINFO[0m[0000] Starting new tools node...                   
[36mINFO[0m[0000] Starting node 'k3d-dev-tools'                
[36mINFO[0m[0001] Creating node 'k3d-dev-server-0'             
[36mINFO[0m[0001] Creating LoadBalancer 'k3d-dev-serverlb'     
[36mINFO[0m[0001] Using the k3d-tools node to gather environment information 
[36mINFO[0m[0001] Starting new tools node...                   
[36mINFO[0m[0001] Starting node 'k3d-dev-tools'                
[36mINFO[0m[0002] Starting cluster 'dev'                       
[36mINFO[0m[0002] Starting servers...                          
[36mINFO[0m[0002] Starting node 'k3d-dev-server-0'             
[36mINFO[0m[0005] All agents already running.                  
[36mINFO[0m[0005] Starting helpers...                          
[36mINFO[0m[0005] Starting node 'k3d-dev-serverlb'             
[36mINFO[0m[0011] Injecting records for hostAliases (incl. host.k3d.internal) and for 3 network members into CoreDNS configmap... 
[36mINFO[0m[0013] Cluster 'dev' created successfully!          
[36mINFO[0m[0013] You can now use it like this:                
kubectl cluster-info
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004h
bck-i-search: _[K[A[15Cgit add *;git commit -m"work";git [4mp[24mush[1B[54Dp_[A[48C[4mp[4mu[24m[1B[51Du_[A[47C[1C[4mu[4ms[24m[1B[51Ds_[A[46C[2C[4ms[4mh[24m[1B[51Dh_[A[45C[24mp[24mu[24ms[24mh[1B[K[A[64C[?2004l[1BThe following paths are ignored by one of your .gitignore files:
Makefile~
[33mhint: Use -f if you really want to add them.[m
[33mhint: Turn this message off by running[m
[33mhint: "git config advice.addIgnoredFile false"[m
[main b6d37d2] work
 2 files changed, 102 insertions(+)
Enumerating objects: 9, done.
Counting objects:  11% (1/9)Counting objects:  22% (2/9)Counting objects:  33% (3/9)Counting objects:  44% (4/9)Counting objects:  55% (5/9)Counting objects:  66% (6/9)Counting objects:  77% (7/9)Counting objects:  88% (8/9)Counting objects: 100% (9/9)Counting objects: 100% (9/9), done.
Delta compression using up to 14 threads
Compressing objects:  25% (1/4)Compressing objects:  50% (2/4)Compressing objects:  75% (3/4)Compressing objects: 100% (4/4)Compressing objects: 100% (4/4), done.
Writing objects:  20% (1/5)Writing objects:  40% (2/5)Writing objects:  60% (3/5)Writing objects:  80% (4/5)Writing objects: 100% (5/5)Writing objects: 100% (5/5), 2.62 KiB | 2.62 MiB/s, done.
Total 5 (delta 1), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (1/1), completed with 1 local object.[K
To github.com:ericmelz/joplin-emelz.git
   397a4d7..b6d37d2  main -> main
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004hlls -la scripts[1m/[0m[0m [?2004l
total 24
drwxr-xr-x   5 ericmelz  staff  160 Sep 28 13:15 .
drwxr-xr-x  10 ericmelz  staff  320 Sep 28 13:05 ..
-rw-r--r--   1 ericmelz  staff   85 Sep 28 13:15 destroy-k3d.sh
-rwxr-xr-x   1 ericmelz  staff  712 Sep 28 13:09 k3d.sh
-rw-r--r--   1 ericmelz  staff   51 Sep 28 12:59 k3d.sh~
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004hcchmod 755 script/dest     s/destroy-k3d.sh[1m [0m[0m [?2004l
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004hmmake destroy-k3d[?2004l
bash scripts/destroy-k3d.sh
[36mINFO[0m[0000] Deleting cluster 'dev'                       
[36mINFO[0m[0000] Deleting cluster network 'k3d-dev'           
[36mINFO[0m[0000] Deleting 1 attached volumes...               
[36mINFO[0m[0000] Removing cluster details from default kubeconfig... 
[36mINFO[0m[0000] Removing standalone kubeconfig file (if there is one)... 
[36mINFO[0m[0000] Successfully deleted cluster dev!            
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004hmmake k3d[?2004l
bash scripts/k3d.sh
CLUSTER_NAME=dev
scripts/k3d.sh: line 11: CLUSTER_LIST: unbound variable
Creating cluster 'dev' using project-specific config...
[36mINFO[0m[0000] portmapping '8880:80' targets the loadbalancer: defaulting to [servers:*:proxy agents:*:proxy] 
[36mINFO[0m[0000] Prep: Network                                
[36mINFO[0m[0000] Created network 'k3d-dev'                    
[36mINFO[0m[0000] Created image volume k3d-dev-images          
[36mINFO[0m[0000] Starting new tools node...                   
[36mINFO[0m[0000] Starting node 'k3d-dev-tools'                
[36mINFO[0m[0001] Creating node 'k3d-dev-server-0'             
[36mINFO[0m[0001] Creating LoadBalancer 'k3d-dev-serverlb'     
[36mINFO[0m[0001] Using the k3d-tools node to gather environment information 
[36mINFO[0m[0001] Starting new tools node...                   
[36mINFO[0m[0001] Starting node 'k3d-dev-tools'                
[36mINFO[0m[0002] Starting cluster 'dev'                       
[36mINFO[0m[0002] Starting servers...                          
[36mINFO[0m[0002] Starting node 'k3d-dev-server-0'             
[36mINFO[0m[0004] All agents already running.                  
[36mINFO[0m[0004] Starting helpers...                          
[36mINFO[0m[0004] Starting node 'k3d-dev-serverlb'             
[36mINFO[0m[0010] Injecting records for hostAliases (incl. host.k3d.internal) and for 3 network members into CoreDNS configmap... 
[36mINFO[0m[0013] Cluster 'dev' created successfully!          
[36mINFO[0m[0013] You can now use it like this:                
kubectl cluster-info
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004h
bck-i-search: _[K[A[15Cmake k3[4md[24m[1B[24Dd_[A[21C[4md[4me[24m[24mstroy-k3d[1B[31De_[A[18C[1C[4me[4ms[24m[1B[22Ds_[A[17C[24md[24me[24ms[1B[K[A[35C[?2004l[1Bbash scripts/destroy-k3d.sh
[36mINFO[0m[0000] Deleting cluster 'dev'                       
[36mINFO[0m[0000] Deleting cluster network 'k3d-dev'           
[36mINFO[0m[0000] Deleting 1 attached volumes...               
[36mINFO[0m[0000] Removing cluster details from default kubeconfig... 
[36mINFO[0m[0000] Removing standalone kubeconfig file (if there is one)... 
[36mINFO[0m[0000] Successfully deleted cluster dev!            
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004h
bck-i-search: _[K[A[15C[4mm[24make destroy-k3d[1B[32Dm_[A[14C[4mm[4ma[24m[1B[17Da_[A[13C[4mm[4ma[4mk[24m[1B[17Dk_[A[12C[2C[4mk[4me[24m[1B[17De_[A[11C[3C[4me[4m [24m[1B[17D _[A[10C[4C[4m [4mk[24m3d        [1B[27Dk_[A[9C[5C[4mk[4m3[24m[1B[17D3_[A[8C[24mm[24ma[24mk[24me[24m [24mk[24m3[1B[K[A[30C[?2004l[1Bbash scripts/k3d.sh
CLUSTER_NAME=dev
scripts/k3d.sh: line 11: CLUSTER_LIST: unbound variable
Creating cluster 'dev' using project-specific config...
[36mINFO[0m[0000] portmapping '8880:80' targets the loadbalancer: defaulting to [servers:*:proxy agents:*:proxy] 
[36mINFO[0m[0000] Prep: Network                                
[36mINFO[0m[0000] Created network 'k3d-dev'                    
[36mINFO[0m[0000] Created image volume k3d-dev-images          
[36mINFO[0m[0000] Starting new tools node...                   
[36mINFO[0m[0000] Starting node 'k3d-dev-tools'                
[36mINFO[0m[0001] Creating node 'k3d-dev-server-0'             
[36mINFO[0m[0001] Creating LoadBalancer 'k3d-dev-serverlb'     
[36mINFO[0m[0001] Using the k3d-tools node to gather environment information 
[36mINFO[0m[0001] Starting new tools node...                   
[36mINFO[0m[0001] Starting node 'k3d-dev-tools'                
[36mINFO[0m[0002] Starting cluster 'dev'                       
[36mINFO[0m[0002] Starting servers...                          
[36mINFO[0m[0002] Starting node 'k3d-dev-server-0'             
[36mINFO[0m[0004] All agents already running.                  
[36mINFO[0m[0004] Starting helpers...                          
[36mINFO[0m[0004] Starting node 'k3d-dev-serverlb'             
[36mINFO[0m[0010] Injecting records for hostAliases (incl. host.k3d.internal) and for 3 network members into CoreDNS configmap... 
[36mINFO[0m[0013] Cluster 'dev' created successfully!          
[36mINFO[0m[0013] You can now use it like this:                
kubectl cluster-info
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004hkkubectl cluster-info[?2004l
Kubernetes control plane is running at https://0.0.0.0:53935
CoreDNS is running at https://0.0.0.0:53935/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://0.0.0.0:53935/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004hkkubectl get svc[?2004l
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.43.0.1    <none>        443/TCP   18s
[1m[7m%[27m[1m[0m                                                                                ]7;file://homer/Users/ericmelz/Data/code/joplin-emelz[0m[27m[24m[Jericmelz@homer joplin-emelz % [K[?2004h