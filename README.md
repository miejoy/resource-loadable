# ResourceLoadable

ResourceLoadable 定义了资源和资源处理者的基础协议与调度机制。文件、网络接口等任何从非内存位置获取固定格式数据的来源，都可以抽象为"可加载资源"。

ResourceLoadable 是自定义 RSV（Resource & State & View）设计模式中 Resource 层的基础模块，为 Resource 提供统一的打开和加载方式。

[![Swift](https://github.com/miejoy/resource-loadable/actions/workflows/test.yml/badge.svg)](https://github.com/miejoy/resource-loadable/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/miejoy/resource-loadable/branch/main/graph/badge.svg)](https://codecov.io/gh/miejoy/resource-loadable)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/swift-6.2-brightgreen.svg)](https://swift.org)

## 依赖

- iOS 15.0+ / macOS 12.0+
- Xcode 26.0+
- Swift 6.2+

## 简介

该模块包含以下核心内容：

- **LoadableResource**：可被加载的资源协议，定义资源类别、额外参数类型和响应类型
- **ResourceLoader**：资源加载器协议，负责处理特定类别资源的实际加载逻辑
- **ResourceCenter**：资源中心单例，管理加载器注册并将资源路由到对应加载器
- **ResourceCategory**：资源类别枚举（file、web、custom 等）
- **ResourceMonitor**：资源事件监听器，用于观察注册、错误等事件
- **Combine+Utils**：Publisher 扩展工具（`asFuture`、`receiveOnce`、`watch`、`wait`）

## 安装

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

在项目中的 Package.swift 文件添加如下依赖：

```swift
dependencies: [
    .package(url: "https://github.com/miejoy/resource-loadable.git", branch: "main"),
]
```

## 使用

### 1. 定义资源

```swift
import ResourceLoadable

/// 定义二级协议简化处理
protocol LoadableFileResource: LoadableResource where ExtraData == Void {
    var fileName: String { get }
}

extension LoadableFileResource {
    static var category: ResourceCategory { .file }
}

/// 具体资源类型
struct FileResource: LoadableFileResource {
    typealias Response = String
    var fileName: String
}
```

### 2. 实现并注册加载器

```swift
import ResourceLoadable
import Combine

class FileResourceLoader: ResourceLoader {
    static let categories: Set<ResourceCategory> = [.file]

    func load<Resource: LoadableResource>(
        _ resource: Resource,
        with extraData: Resource.ExtraData
    ) -> AnyPublisher<Resource.Response, Error> {
        guard let fileRes = resource as? LoadableFileResource else {
            return Fail(error: LoadResourceError.resourceTypeError).eraseToAnyPublisher()
        }
        // 实际读取文件逻辑...
        return Just(fileRes.fileName)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// 在 App 启动时注册
let loader = FileResourceLoader()
ResourceCenter.shared.registerLoader(loader)
```

### 3. 使用资源

```swift
import ResourceLoadable

let resource = FileResource(fileName: "config.json")

// 持续监听（Combine）
let cancellable = resource.open().sink { completion in
    // 处理完成事件
} receiveValue: { content in
    print("收到内容：\(content)")
}

// 只获取一次（回调）
resource.openOnce { result in
    switch result {
    case .success(let content): print(content)
    case .failure(let error): print(error)
    }
}

// 只获取一次（async/await）
let content = try await resource.openOnce()
```

### 4. Combine 工具方法

```swift
import ResourceLoadable
import Combine

// asFuture：将任意 Publisher 转为只返回一次的 Future
let future = somePublisher.asFuture()

// receiveOnce：订阅并只接收第一个值
somePublisher.receiveOnce { result in
    // 处理结果
}

// watch：在不中断数据流的情况下观察每个值
let cancellable = somePublisher
    .watch { value in print("观察到：\(value)") }
    .sink { _ in } receiveValue: { _ in }

// wait：等待 Future 的结果（async/await）
let value = try await someFuture.wait()
```

### 5. 监听资源事件

```swift
import ResourceLoadable

let token = ResourceMonitor.shared.addObserver(myObserver)
// token 取消时自动移除观察者
token.cancel()

class MyObserver: ResourceMonitorObserver {
    func receiveResourceEvent(_ event: ResourceEvent) {
        switch event {
        case .addResourceLoader(let loader, let category):
            print("注册加载器：\(category)")
        case .noLoaderFoundForResource(let category):
            print("找不到加载器：\(category)")
        case .duplicateRegistration(_, let new):
            print("重复注册：\(new)")
        }
    }
}
```

## 作者

黄磊, raymond0huang@gmail.com

## License

ResourceLoadable is available under the MIT license. See the LICENSE file for more info.
