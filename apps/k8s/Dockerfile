FROM greenbox:for_apps

ARG DOCKER_PROXY=172.17.0.4

RUN echo "docker proxy: $DOCKER_PROXY" \
 && echo "Acquire::HTTP::Proxy \"http://$DOCKER_PROXY:3142\";" > /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

RUN echo "deb-src http://deb.debian.org/debian jessie main" >> /etc/apt/sources.list
RUN apt-get update -y


# ================= /opt/apps/k8s =========================================================

ENV CPPFLAGS="-I/opt/apps/k8s/include" CFLAGS="-I/opt/apps/k8s/include" LDFLAGS="-L/opt/apps/k8s/lib"

#https://github.com/kubernetes/kubernetes/releases
# https://github.com/coreos/etcd/releases/
ENV K8S_HOME=/opt/apps/k8s K8S_VERSION=1.6.3 ETCD_VERSION=3.1.7 HELM_VERSION=2.4.1

RUN mkdir -p $K8S_HOME/bin

RUN cd $K8S_HOME/bin && curl -LO https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 &&\
   chmod +x cfssl_linux-amd64 &&\
   mv cfssl_linux-amd64 cfssl


RUN cd $K8S_HOME/bin && curl -LO https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 &&\
     chmod +x cfssljson_linux-amd64 &&\
     mv cfssljson_linux-amd64 cfssljson


RUN curl -LO https://github.com/coreos/etcd/releases/download/v3.1.4/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz &&\
   tar -xvf etcd-v${ETCD_VERSION}-linux-amd64.tar.gz &&\
   mv etcd-v${ETCD_VERSION}-linux-amd64/etcd* $K8S_HOME/bin/


RUN cd $K8S_HOME/bin &&\
    curl -LO https://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/linux/amd64/kube-apiserver  &&\
    curl -LO https://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/linux/amd64/kube-controller-manager &&\
    curl -LO https://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/linux/amd64/kube-scheduler &&\
    curl -LO https://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/linux/amd64/kubectl &&\
    chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl


RUN curl -sLO https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz &&\
    tar -xvf helm-v${HELM_VERSION}-linux-amd64.tar.gz &&\
    mv helm-v${ETCD_VERSION}-linux-amd64/helm* $K8S_HOME/bin/
