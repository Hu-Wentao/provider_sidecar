## v1.4.x

- Intent：描述用户的操作，UI层输入的事件，是一种特殊的Event；显然UI可以直接发送Event，命令State变更。
  不同Intent可能会对应不同的多个Event（非正交）
- Event：描述状态如何变更，对应State的变更，即emit某个Event后，会立即触发State变化；（先Event后State）
         Event也用于消息通知，（先State后Event）
  不同的Event对State的操作是正交的
- State：描述当前Model的状态；

- 规划
  - evt入口同时接入state，即切换state也作为一种事件：要求freezed生成的代码继承指定抽象类
  - evt入口接入Exception（onCatch），异常也作为一种事件：要求同上
  - log接入evt，所有的evt都作为log
## v1.3.x
推荐使用 ModelSidecar 管理状态