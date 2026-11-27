tags: aws, systems-manager, session-manager, jit, iam, supply-chain, security

# Session Manager は、普段使わないチームだけ JIT にする

Systems Manager の just-in-time node access は、申請と承認があったときだけ一時的にノードにつなげる仕組み。
時間が来たら閉じ、誰が誰の承認で入ったかが残る。

全員に使わせると、承認が形だけになって手間が増える。
対象は、**普段は Session Manager を使わないのに、つなげる権限だけ持っている人**に絞る。

## 分け方

- **管理するチーム**：いつでも入れる。`ssm:StartSession` を `ssm:resourceTag/team` で自チームのノードに絞る
- **ほかのチーム**：常時の権限を外し、必要なときは JIT で申請して管理チームが承認する
- **委託先**：JIT。保守用の VPN や RDP を置き換えれば、作業していない期間は入口が閉じている

常時権限を外すだけで、そのチームの認証情報が盗まれても Session Manager からは入れない。

## 管理チームは「入ったら鳴る」

管理チームには申請させず、本番の `StartSession` を EventBridge で拾って Slack に流す。

承認者を同じチームにすれば「本番作業は二人で」の確認記録にもなる。

承認ポリシーの対象をタグで絞れるか、常時権限と JIT の共存、料金は未確認。
