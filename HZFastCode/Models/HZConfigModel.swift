//
//  HZConfigModel.swift
//  FastCode
//
//  Created by HertzWang on 2019/3/27.
//  Copyright © 2019 HertzWang. All rights reserved.
//

import Cocoa
import CommonCrypto


class HZConfigModel: NSObject {
    
    var title: String = "" /// 标题
    var summary: String = "" /// 概要
    var contents: String = "" /// 内容
    var language: String = "" /// 语言
    var prefix: String = "" /// 前缀
    var scopes: String = "" /// 作用域
    var identifier: String = "" /// 代码块唯一标识符 MD5如：FF167DB4-0C2D-4F6D-9A2B-0C0785239FFB
    
    class func model(title: String = "", summary: String = "", contents: String, language: String = "Swift", prefix: String, scopes: [String] = ["All"]) -> HZConfigModel {
        
        let model = HZConfigModel()
        model.title = title
        model.summary = summary
        model.contents = contents
        model.language = language
        model.prefix = prefix
        scopes.forEach { scope in
            model.scopes += "<string>\(scope)</string>\n"
        }
        model.identifier = kFCSnippetIdentifierPrefix.appending(prefix).hz_md5()
        
        return model
    }
    
    class func model(_ json: String) -> HZConfigModel? {
        guard let data = json.data(using: .utf8) else { return nil }
        
        let model = HZConfigModel()
        if let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: String] {
            model.title = dict["title"] ?? ""
            model.summary = dict["summary"] ?? ""
            model.contents = dict["contents"] ?? ""
            model.language = dict["language"] ?? ""
            model.prefix = dict["prefix"] ?? ""
            model.scopes = dict["scopes"] ?? ""
            model.identifier = dict["identifier"] ?? ""
        }
        
        return model
    }
    
    func isEmpty() -> Bool {
        return self.prefix.isEmpty
    }
    
    func jsonValue() -> String {
        var result = ""
        if let data = try? JSONSerialization.data(withJSONObject: dictValue(), options: JSONSerialization.WritingOptions.fragmentsAllowed) {
            result = String.init(data: data, encoding: .utf8) ?? ""
        }
        return result
    }
    
    /// 写入到文件的数据
    func data() -> Data? {
        var text = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>IDECodeSnippetCompletionPrefix</key>
                <string>FastCodePrefix</string>
                <key>IDECodeSnippetCompletionScopes</key>
                <array>
                    FastCodeScopes
                </array>
                <key>IDECodeSnippetContents</key>
                <string>FastCodeContents</string>
                <key>IDECodeSnippetIdentifier</key>
                <string>FastCodeIdentifier</string>
                <key>IDECodeSnippetLanguage</key>
                <string>Xcode.SourceCodeLanguage.FastCodeLanguage</string>
                <key>IDECodeSnippetSummary</key>
                <string>FastCodeSummary</string>
                <key>IDECodeSnippetTitle</key>
                <string>FastCodeTitle</string>
                <key>IDECodeSnippetUserSnippet</key>
                <true/>
                <key>IDECodeSnippetVersion</key>
                <integer>2</integer>
            </dict>
            </plist>
            """
        
        text = text.replacingOccurrences(of: kFCIDECodeSnippetTitle, with: self.title)
        text = text.replacingOccurrences(of: kFCIDECodeSnippetSummary, with: self.summary)
        text = text.replacingOccurrences(of: kFCIDECodeSnippetContents, with: self.contents)
        text = text.replacingOccurrences(of: kFCIDECodeSnippetLnaguage, with: self.language)
        text = text.replacingOccurrences(of: kFCIDECodeSnippetCompletionPrefix, with: self.prefix)
        text = text.replacingOccurrences(of: kFCIDECodeSnippetCompletionScopes, with: self.scopes)
        text = text.replacingOccurrences(of: kFCIDECodeSnippetIdentifier, with: self.identifier)
        
        return text.data(using: .utf8) ?? data()
    }
    
    fileprivate func dictValue() -> [String: String] {
        return [
            "title" : self.title,
            "summary" : self.summary,
            "contents" : self.contents,
            "language" : self.language,
            "prefix" : self.prefix,
            "scopes" : self.scopes,
            "identifier" : self.identifier,
        ]
    }
}

extension String {
    func hz_md5() -> String {
        let str = self.cString(using: .utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: .utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let md = UnsafeMutablePointer<UInt8>.allocate(capacity: digestLen)
        CC_MD5(str, strLen, md)
        let arr = [3, 5, 7, 9]
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", md[i])
            if arr.contains(i) {
                hash.append("-")
            }
        }
        free(md)
        return String(format: hash.uppercased as String)
    }
}

/*
 描述：
 
 1. IDECodeSnippetCompletionPrefix 对应 Completion，代码块前缀，唯一
 2. IDECodeSnippetCompletionScopes 对应 Avaiability，代码块作用域，多选
 3. IDECodeSnippetContents 对应大文本框，代码文本，例如 // MARK: - &lt;#mark name#&gt;
 4. IDECodeSnippetIdentifier 自动生成，代码块唯一标识符，格式为 8位-4位-4位-4位-12位 的16进制，如：86BDFF60-EDE0-4904-8983-C666CA2F3024
 5. IDECodeSnippetLanguage 对应 Language，代码块编程语言，格式为 Xcode.SourceCodeLanguage.语言
 6. IDECodeSnippetSummary 对应 Summary输入框，代码块概要，可为空
 7. IDECodeSnippetTitle 对应标题输入框，代码块标题
 8. IDECodeSnippetUserSnippet 固定为 true，代码块类型（User）
 9. IDECodeSnippetVersion 固定为 2，代码块版本
 
 替换：
 
    FastCodeTitle 标题
    FastCodeSummary 概要
    FastCodeContents 内容
    FastCodeLanguage 编程语言
    FastCodePrefix 前缀
    FastCodeScopes 作用域
    FastCodeIdentifier 唯一标识符
 
 
 源文件：
 
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
     <key>IDECodeSnippetCompletionPrefix</key>
     <string>hzmark</string>
     <key>IDECodeSnippetCompletionScopes</key>
     <array>
         <string>All</string>
     </array>
     <key>IDECodeSnippetContents</key>
     <string>// MARK: - &lt;#mark name#&gt;</string>
     <key>IDECodeSnippetIdentifier</key>
     <string>86BDFF60-EDE0-4904-8983-C666CA2F3024</string>
     <key>IDECodeSnippetLanguage</key>
     <string>Xcode.SourceCodeLanguage.Swift</string>
     <key>IDECodeSnippetSummary</key>
     <string></string>
     <key>IDECodeSnippetTitle</key>
     <string>HZ MARK</string>
     <key>IDECodeSnippetUserSnippet</key>
     <true/>
     <key>IDECodeSnippetVersion</key>
     <integer>2</integer>
 </dict>
 </plist>

 
 模版：
 
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
     <key>IDECodeSnippetCompletionPrefix</key>
     <string>FastCodePrefix</string>
     <key>IDECodeSnippetCompletionScopes</key>
     <array>
         FastCodeScopes
     </array>
     <key>IDECodeSnippetContents</key>
     <string>FastCodeContents</string>
     <key>IDECodeSnippetIdentifier</key>
     <string>FastCodeIdentifier</string>
     <key>IDECodeSnippetLanguage</key>
     <string>Xcode.SourceCodeLanguage.FastCodeLanguage</string>
     <key>IDECodeSnippetSummary</key>
     <string>FastCodeSummary</string>
     <key>IDECodeSnippetTitle</key>
     <string>FastCodeTitle</string>
     <key>IDECodeSnippetUserSnippet</key>
     <true/>
     <key>IDECodeSnippetVersion</key>
     <integer>2</integer>
 </dict>
 </plist>


 补充：
 
 <key>IDECodeSnippetCompletionScopes</key>
 <array>
     <string>ClassInterfaceMethods</string>
     <string>TopLevel</string>
     <string>CodeBlock</string>
     <string>ClassInterfaceVariables</string>
 </array>
 
*/
