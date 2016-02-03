# Copyright 2016 Produban Servicios Informáticos Generales S.L.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM docker.io/debian:jessie

MAINTAINER Global PaaS global_paas@produban.com

ARG http_proxy
ARG https_proxy
ARG no_proxy

COPY cassandra.list /etc/apt/sources.list.d/cassandra.list

# Keys are manually included within the project to avoid problems with proxies.

COPY F758CE318D77295D.key /tmp/F758CE318D77295D.key
COPY 2B5C1B00.key /tmp/2B5C1B00.key
COPY 0353B12C.key /tmp/0353B12C.key

RUN cat /tmp/F758CE318D77295D.key | apt-key add -
RUN cat /tmp/2B5C1B00.key | apt-key add -
RUN cat /tmp/0353B12C.key | apt-key add -

# If you are NOT behind a proxy (or you use Docker 1.9 and can pass proxy variables from CLI), use this
RUN apt-get update
RUN apt-get -qq -y install procps cassandra
# If you are behind a proxy, comment the two previous lines, uncomment the two following ones and change 'proxyHost' and 'proxyPort' with appropriate values
#RUN env http_proxy=http://proxyHost:proxyPort bash -c 'apt-get update'
#RUN env http_proxy=http://proxyHost:proxyPort bash -c 'apt-get -qq -y install procps cassandra'

COPY cassandra.yaml /etc/cassandra/cassandra.yaml
COPY cassandra-env.sh /etc/cassandra/cassandra-env.sh
COPY logback.xml /etc/cassandra/logback.xml

COPY run.sh /run.sh
COPY kubernetes-cassandra.jar /kubernetes-cassandra.jar

RUN chmod a+x /run.sh && \
    mkdir -p /cassandra_data/data && \
    chown -R cassandra.cassandra /etc/cassandra /cassandra_data && \
    chmod o+w -R /etc/cassandra /cassandra_data

VOLUME ["/cassandra_data/data"]

USER cassandra

CMD /run.sh
