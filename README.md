FessCloud
==========

## 概要

FessCloudはSolrCloudを用いたFess環境です。
ここではSolrCloudをFessで利用するための構築用シェルスクリプトを提供します。
実行すると、ZooKeeper+Solrサーバ、Solrサーバ、Fessサーバのディレクトリが作成できます。
以下のような構成図になります。

                  　　  利用者
                         |
    +-------------------------------------------+
    |               Fessサーバ群                |
    +-------------------------------------------+
                         |
    +-------------------------------------------+
    |                 SolrCloud                 |
    |+------------------------+ +--------------+|
    || ZooKeeper+Solrサーバ群 | | Solrサーバ群 ||
    |+------------------------+ +--------------+|
    +-------------------------------------------+

FessサーバはSolrCloudに対して検索/更新リクエストを要求することができます。
FessサーバもSolrCloudのスケール量に合わせて、サーバの追加糖が可能です。

ZooKeeperアンサンブルはSolrに含まれるものを利用しています。
ZooKeeperアンサンブルが既に存在する場合はSolrサーバだけで利用することができます。
ここで提供するスクリプトでは、ZK+Solr用のSolrサーバとSolrサーバのみの2種類の設定を生成することができます。

## 設定

config.shに各スクリプトの実行に必要な設定が記述されています。
必要に応じて変更してください。

    # ZK+Solrサーバの名前(ディレクトリ名などに利用)
    ZK_SOLR_SERVER_NAMES=("zksolr-server-1" "zksolr-server-2" "zksolr-server-3")
    # ZK+Solrサーバのホスト名
    ZK_SOLR_SERVER_HOSTS=("localhost" "localhost" "localhost")
    # ZK+SolrサーバのSolrのポート番号
    ZK_SOLR_SERVER_SOLR_PORTS=(8180 8280 8380)
    # ZK+SolrサーバのSolrのシャットダウン用ポート番号
    ZK_SOLR_SERVER_SOLR_SHUTDOWN_PORTS=(8181 8281 8381)
    # ZK+SolrサーバのZooKeeperのポート番号
    ZK_SOLR_SERVER_ZK_PORTS=(9180 9280 9380)
    
    # Solrサーバの名前(ディレクトリ名などに利用)
    SOLR_SERVER_NAMES=("solr-server-1" "solr-server-2")
    # SolrサーバのSolrのポート番号
    SOLR_SERVER_PORTS=(8480 8580)
    # SolrサーバのSolrのシャットダウン用ポート番号
    SOLR_SERVER_SHUTDOWN_PORTS=(8481 8581)

    # Fessサーバの名前(ディレクトリ名などに利用)
    FESS_SERVER_NAMES=("fess-server-1")
    # FessサーバのSolrのポート番号
    FESS_SERVER_PORTS=(8080)
    # FessサーバのSolrのシャットダウン用ポート番号
    FESS_SERVER_SHUTDOWN_PORTS=(8081)

    # ZooKeeper内で保持するFessのSolr設定名
    FESS_CONF=fessconf
    # Solrのコレクションエイリアス名(Fessサーバのsolrlib.diconに記述されます)
    FESS_COLLECTION_ALIAS=fess-cloud
    # Solrのコレクション名
    FESS_COLLECTION=fess-collection

    # サンプルスクリプト実行時に利用される項目
    # シャード数
    NUM_SHARDS=5
    # シャード内のノード数
    REPLICATION_FACTOR=3
    # ノードの最大シャード数
    MAX_SHARDS_PER_NODE=3


## 構築

以下を実行することでconfig.shの情報を元にtargetディレクトリに各インスタンスのディレクトリが生成されます。

    $ bash ./setup_cloud.sh

複数のサーバで実行する場合は、targetディレクトリに生成されたものを各サーバで実行してください。
上記のスクリプトの実行後、各インスタンスを起動し、Fess用のSolr設定をZooKeeperにアップロードして、コレクションにリンクする必要があります。
コレクションはFessなどの検索アプリケーションからアクセスするインデックスであり、コレクションは複数のシャードから構成されます。
シャードは複数のSolrのCoreでインデックスを管理して、1つのリーダーのノード(SolrのCore)と複数のレプリカのノード(SolrのCore)で構成されます。

### Fess用設定の登録

ZooKeeperにFess用のSolr設定(schema.xmlとかsolrconfig.xmlとか)を登録します。

    $ java -classpath .:$BUILD_DIR/solr-jars/* org.apache.solr.cloud.ZkCLI -zkhost $ZK_HOSTS -cmd upconfig -confname $FESS_CONF -confdir $BUILD_DIR/solr-config
    $ java -classpath .:$BUILD_DIR/solr-jars/* org.apache.solr.cloud.ZkCLI -zkhost $ZK_HOSTS -cmd linkconfig -collection $FESS_COLLECTION -confname $FESS_CONF

$〜の環境変数で記載していますが、setup\_cloud.shを実行すると実行完了時に展開された形で出力されるのでその内容を参照してください。

### コレクションのエイリアス作成

Fessから参照するコレクションをエイリアスとしておくことで、Fessの設定を変更することなく、コレクションの差し替えなどが可能になります。
たとえば、インデックスのリカバリを別なコレクションで実施して、リカバリ完了後にエイリアスを変更することで有効にすることができます。
SolrCloudがlocalhostの8180で動いていて、コレクション名がfess-collectionをエイリアス名がfess-cloudに設定する場合は以下のように実行します。

    $ curl 'localhost:8180/solr/admin/collections?action==CREATEALIAS&name=fess-cloud&collections=fess-collection'

### コレクションの作成

Solrの[Collection API](https://cwiki.apache.org/confluence/display/solr/Collections+API)を用いて作成します。
たとえば、SolrCloudがlocalhostの8180で動いていて、コレクション名がfess-collectionでシャード数が2で、各シャードが2ノード持つものを作成する場合は以下のように実行します。

    $ curl 'localhost:8180/solr/admin/collections?action=CREATE&name=fess-collection&numShards=2&replicationFactor=2&maxShardsPerNode=2'

### コレクションの削除

コレクション名がfess-collectionのものを削除する場合は以下のように実行します。

    $ curl 'localhost:8180/solr/admin/collections?action=DELETE&name=fess-collection'

## サンプル

試しに構築・実行するような場合に利用するサンプルスクリプトを用意してあります。
サンプルスクリプト内にはsetup\_cloud.shの処理も含まれているので、sample\_startup.shを実行するだけでFessCloudの実行が行われます。
FessCloudを独自に作成するときの参考にもなるかと思います。

### 構築・実行

sample_startup.shを実行することで、ローカルPC上にconfig.shで指定した環境を作成し、FessCloudを起動することができます。

    $ bash ./sample_startup.sh

様々なログが出ますが、ログ出力が一段落した頃に http://localhost:8180/solr/#/~cloud にアクセスすることでSolrCloudの状態を確認することができます。
デフォルトではZK+Solrサーバが3インスタンス、Solrサーバが2インスタンス、Fessが1インスタンスを起動します。
シャード数が5で、1シャード当たり3ノード保持する構成で生成・実行されます。
ロースペックのPCなどで試す場合は、config.shでSOLR\_SERVER\_NAMESを空にして、NUM\_SHARDSを3、REPLICATION\_FACTORを2などにすると良いと思います。

Solrの管理画面でSolrCloudの状態を確認できたら、http://localhost:8080/fess/ にアクセスして、通常のFessと同様にクロール設定を行い、クロールの実行、検索を試すことができます。

### 停止

    $ bash ./sample_shutdown.sh

上記を実行することでsample_startup.shで実行したすべてのインスタンスを停止することができます。


