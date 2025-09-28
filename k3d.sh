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