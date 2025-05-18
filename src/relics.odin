package main


RelicType :: enum {
	None,
	Test,
}


get_relic_name :: proc(type: RelicType) -> cstring {
	switch (type) {

	case .None:
		return "None"
	case .Test:
		return "Test"
	}


	return ""
}


get_relic_texture_name :: proc(type: RelicType) -> Texture_Name {
	switch (type) {
	case .None:
		return .None
	case .Test:
		return .None
	}


	return .None
}
