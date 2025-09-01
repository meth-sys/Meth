; ModuleID = 'main'
source_filename = "main"

@str = private constant [6 x i8] c"Hello\00"

declare i32 @write(i32, ptr, i64)

define void @print(ptr %0, i64 %1) {
entry:
  %2 = call i32 @write(i32 1, ptr %0, i64 %1)
  ret void
}

define i32 @main() {
entry:
  %hello = alloca ptr, align 8
  store ptr @str, ptr %hello, align 8
  %size = alloca i64, align 8
  store i64 5, ptr %size, align 4
  %hello1 = load ptr, ptr %hello, align 8
  %size2 = load i64, ptr %size, align 4
  call void @print(ptr %hello1, i64 %size2)
  ret i32 0
}
