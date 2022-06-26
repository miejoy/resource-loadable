# ResourceLoadable

ResourceLoadable 表面了资源和资源处理者应该如何定义。我们可以理解文件是一个可加载的资源，同样网络接口也可以被理解成一个可加载的资源。实际上只要是从非内存的其他位置获取固定格式的数据都可以被理解成加载可加载资源。

ResourceLoadable 是自定义 RSV(Resource & State & View) 设计模式中 Resource 层的基础模块，负责给 Resource 提供统一的打开和加载方式。

[![Swift](https://github.com/miejoy/resource-loadable/actions/workflows/test.yml/badge.svg)](https://github.com/miejoy/resource-loadable/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/miejoy/resource-loadable/branch/main/graph/badge.svg)](https://codecov.io/gh/miejoy/resource-loadable)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/swift-5.4-brightgreen.svg)](https://swift.org)

## 依赖

- iOS 13.0+ / macOS 10.15+
- Xcode 14.0+
- Swift 5.4+

## 简介

### 该模块包含如下内容:

- 定义了如下基础协议:
  - ResourceLoadable: 可被加载的资源，如 文件、网络接口等
  - ResourceHandleable: 可处理资源的资源处理器

## 安装

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

在项目中的 Package.swift 文件添加如下依赖:

```swift
dependencies: [
    .package(url: "https://github.com/miejoy/resource-loadable.git", from: "0.1.0"),
]
```

## 使用

### ResourceLoadable 使用

1、定义一个资源

```swift
import ResourceLoadable

/// 可以通过定义二级协议来简化 handler 的处理
protocol FileResourceLoadable: ResourceLoadable where ExtraData == Void {
    var fileName: String { get }
}

/// 扩展默认资源类型
extension FileResourceLoadable {
    static var category: ResourceCategory { .file }
}

/// 定义一个文件资源
struct FileResource: FileResourceLoadable {
    typealias Response = String
    var fileName: String
}
```

2、使用这个资源

```swift
import ResourceLoadable

/// 创建一个资源
let fileResource = FileResource(fileName: "fileName")

var arrReceives = [String]()
/// 直接打开资源，打开资源不需要关系谁能处理
let cancellable = fileResource.open().sink { completion in
} receiveValue: { str in
    arrReceives.append(str)
}

cancellable.cancel()
```

### ResourceHandleable 使用

1、定义一个资源处理器

```swift
import ResourceLoadable

class FileHandler: ResourceHandleable {
    static var handlerCategorys: Set<ResourceCategory> = [.file]
        
    func load<Resource>(_ resource: Resource, with extraData: Resource.ExtraData) -> AnyPublisher<Resource.Response, Error> where Resource : ResourceLoadable {
        guard let theResource = resource as? FileResourceLoadable else {
            let publisher = PassthroughSubject<Resource.Response, Error>()
            publisher.send(completion: .failure(LoadResourceError.resourceTypeError))
            return publisher.eraseToAnyPublisher()
        }
        ...
    }
}
```

2、注册对于资源处理器

```swift
import ResourceLoadable

let fileHandler = FileHandler()
ResourceManager.shared.registerHandler(fileHandler)
```

## 作者

Raymond.huang: raymond0huang@gmail.com

## License

ResourceLoadable is available under the MIT license. See the LICENSE file for more info.
