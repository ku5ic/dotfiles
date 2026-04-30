local typescript_inlay_hints = {
	enumMemberValues = { enabled = true },
	functionLikeReturnTypes = { enabled = true },
	parameterNames = { enabled = "literals" },
	parameterTypes = { enabled = true },
	propertyDeclarationTypes = { enabled = true },
	variableTypes = { enabled = false },
}

return {
	settings = {
		vtsls = {
			autoUseWorkspaceTsdk = true,
			experimental = {
				maxInlayHintLength = 30,
				completion = {
					enableServerSideFuzzyMatch = true,
				},
			},
		},
		typescript = {
			updateImportsOnFileMove = { enabled = "always" },
			suggest = { completeFunctionCalls = true },
			inlayHints = typescript_inlay_hints,
		},
		javascript = {
			updateImportsOnFileMove = { enabled = "always" },
			inlayHints = typescript_inlay_hints,
		},
	},
}
