//
//  CLImageEditorExtension.swift
//  Pods
//
//  Created by Gabe Kangas on 10/30/16.
//
//

import Foundation
import CLImageEditor

extension CLImageEditor {
    func setup() {
        disable(tools: ["CLToneCurveTool", "CLFilterTool", "CLEffectTool", "CLAdjustmentTool", "CLBlurTool", "CLRotateTool", "CLSplashTool", "CLResizeTool", "CLEmoticonTool", "CLStickerTool"])
        rename(tool: "CLDrawTool", name: "Markup")
    }
    
    func disable(tools: [String]) {
        for tool in tools {
            let tool = toolInfo.subToolInfo(withToolName: tool, recursive: true)
            tool?.available = false
        }
    }
    
    func rename(tool: String, name: String) {
        let tool = toolInfo.subToolInfo(withToolName: tool, recursive: true)
        tool?.title = name
    }
}
