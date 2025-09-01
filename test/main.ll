; ModuleID = 'main'
source_filename = "main"

define i32 @main() {
entry:
  %age = alloca i32, align 4
  store i32 14, ptr %age, align 4
  ret i32 0
}
