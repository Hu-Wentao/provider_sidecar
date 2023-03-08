# ProviderSidecar

> 选择Provider: 可通过DevTools查看当前状态

## v1.5.x

> 与BloC的区别：同一个Model支持多个实例，BloC只允许单个实例存在

### 1.5.2

- 新增 SidecarEvtMx 取代 EvtEntranceMx，不再依赖 BaseSidecar
- 新增 SidecarModel 取代 SidecarProvider
  - [SidecarModel] 就是数据本身，只不过[ChangeNotifier]赋予它通知UI刷新的能力。
      通过 final id 来标识唯一的[SidecarModel]实例
    [SidecarProvider]则更像是一个数据的提供器，代理数据类向UI发出通知。

### 1.5.1

- 基于 v1.4.x
- 新增 SidecarProvider
- 移除Intent/Act，只保留Event。
  - 对于UI操作，需要将Intent转换为对应的完成时Event。如 Intent‘提交表单’转换为 Event‘已发送表单提交请求’
- 移除SubState
- 移除ProviderSidecar。改用ModelSidecar

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