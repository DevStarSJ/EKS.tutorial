# EKS Tutorial

EKS 관련 자원을 AWS에 배포하여 docker image를 통해서 서버 배포, rollback, auto-scaling 까지 동작하는 것까지의 실습을 다룬다.

### 참고

- [AWS EKS Introduction | Terraform - HashiCorp Learn](https://learn.hashicorp.com/terraform/aws/eks-intro)의 terraform 코드를 거의 그대로 활용하였다. AutoScalingGroup 의 Metric Alarm이 해당 코드에는 빠져있어서 추가하였다.
- Kubernetes 설정 파일은 [Documentation - Concepts | kubernetes](https://kubernetes.io/docs/concepts)를 참조하여 작성하였다.
- [Kubernetes Metrics Server Github](https://github.com/kubernetes-incubator/metrics-server)에서 Metrics Server를 실행하는 yaml 파일들을 가져왔다.

## Step 1. EKS 배포

`terraform/variable.tfvars` 파일내의 AWS credential / region 수정

```shell
cd terraform
terraform init
terraform apply -var-file=variable.tfvars
```

output 폴더에 `config`, `config_map_aws_auth.yaml` 파일이 생성됨.

`config`파일을 `~/.kube`로 복사
```shell
cd ..
cp output/config ~/.kube/
```

`kubectl`의 실행환경을 `EKS Cluster`로 연결
```shell
kubectl apply -f output/config_map_aws_auth.yaml
```

현재 생성되어 있는 kubernetes worker-node와 resource 확인
```shell
kubectl get no,all
```

이미지 1

AutoScaling 기능을 사용하려면 Cluster에서 Pod의 상태를 모니터링 해야하므로. Metrics Server를 배포

```shell
kubectl apply -f example/metrics-server.1.8+
```

dummy http server 배포 ([jasonrm/dummy-server](https://hub.docker.com/r/jasonrm/dummy-server)를 이용)

##### deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: testapp-deployment
  labels:
    app: testapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: testapp
  template:
    metadata:
      labels:
        app: testapp
    spec:
      containers:
      - name: testapp
        image: jasonrm/dummy-server
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 15
        readinessProbe:
          exec:
            command:
            - ls
        ports:
        - name: http-server
          containerPort: 8080
          protocol: TCP
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 300m
```

이미지 2

pod에 직접 연결해서 확인 (pod 이름은 직접 확인해서 수정해야함)

```shell
kubectl port-forward testapp-deployment-7c9b78c7d5-gq4v7 8080:8080
```

<http://localhost:8080> 로 접속하여 `200` 메세지 확인

`Ctrl + C`로 종료

외부에서 접속가능하도록 단일 end-point를 가지는 service를 생성 (AWS LoadBalander가 생성되어 연결됨)

##### service.yaml
```yaml
kind: Service
apiVersion: v1
metadata:
  name: testapp-service
spec:
  selector:
    app: testapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: http-server
  type: LoadBalancer
```

```shell
kubectl apply -f example/service.yaml
```

그림 3

그림 4

AWS Console -> EC2 -> Load Balancer 상의 **DNS Name**과 kubectl에서의 service **EXTERNAL-IP**가 같은 것을 볼 수 있다.

해당 주소로 접속을 하여 `200`메세지 확인

해당 pod를 삭제

```shell
kubectl delete deployment --all
```

Horizontal Pod Autoscaler 설정
```shell
kubectl autoscale deployment testapp-deployment --cpu-percent=10 --min=1 --max=50
```

```shell
kubectl exec -it testapp-deployment-68d9c498dc-2nwpw  -- sh -c "while true; do wget -O - -q http://naver.com; done"
```

```shell
terraform destroy -var-file=variable.tfvars
```

```shell
kubectl get all --namespace=kube-system

kubectl logs metrics-server-85cc795fbf-x54fs --namespace=kube-system
```