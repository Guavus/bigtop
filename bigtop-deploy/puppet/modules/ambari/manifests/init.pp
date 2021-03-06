# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class ambari {

  class deploy ($roles) {
    if ("ambari-server" in $roles) {
      include ambari::server
    }

    if ("ambari-agent" in $roles) {
      include ambari::agent
    }
  }

  class server {
    package { "ambari-server":
      ensure => latest,
    }

    exec {
        "server setup":
           command => "/usr/sbin/ambari-server setup -s",
           require => [ Package["ambari-server"] ]
    }

    # FIXME: this is currently a workaround for 2.5
    file { ["/var/lib/ambari-server/resources/stacks/Bigtop", "/var/lib/ambari-server/resources/stacks/Bigtop/1.2.0"]:
      ensure => 'directory',
      require => [ Package["ambari-server"] ]
    }

    service { "ambari-server":
        ensure => running,
        require => [ Package["ambari-server"], Exec["server setup"], File["/var/lib/ambari-server/resources/stacks/Bigtop/1.2.0"] ],
        hasrestart => true,
        hasstatus => true,
    }
  }

  class agent($server_host = "localhost") {
    package { "ambari-agent":
      ensure => latest,
    }

    file {
      "/etc/ambari-agent/conf/ambari-agent.ini":
        content => template('ambari/ambari-agent.ini'),
        require => [Package["ambari-agent"]],
    }

    service { "ambari-agent":
        ensure => running,
        require => [ Package["ambari-agent"], File["/etc/ambari-agent/conf/ambari-agent.ini"] ],
        hasrestart => true,
        hasstatus => true,
    }
  }
}
