// RUN: llvm-tblgen -gen-register-info -I %p/../../include %s | FileCheck %s

include "llvm/Target/Target.td"

def TestTarget : Target;

def lo : SubRegIndex<32>;
def hi : SubRegIndex<32, 32>;

def ALo : Register<"alo">;
def AHi : Register<"ahi">;
def BLo : Register<"blo">;
def BHi : Register<"bhi"> {
  let isArtificial = 1;
}

let SubRegIndices = [lo, hi], CoveredBySubRegs = 1 in {
  def A : RegisterWithSubRegs<"a", [ALo, AHi]>;
  def B : RegisterWithSubRegs<"b", [BLo, BHi]> {
    let ClobberedBySubRegs = 1;
  }
}

def AOnly : RegisterClass<"Test", [i64], 64, (add A)>;
def BOnly : RegisterClass<"Test", [i64], 64, (add B)>;
def Mixed : RegisterClass<"Test", [i64], 64, (add A, B)>;

// CHECK: MixedRegClassID = [[MIXED:[0-9]+]],
// CHECK-NEXT: AOnlyRegClassID = {{[0-9]+}},
// CHECK-NEXT: BOnlyRegClassID = [[B:[0-9]+]],

// CHECK: static const LaneBitmask TestTargetSubRegIndexLaneMaskTable[] = {
// CHECK-NEXT: LaneBitmask::getAll(),
// CHECK-NEXT: LaneBitmask(0x0000000000000001), // hi
// CHECK-NEXT: LaneBitmask(0x0000000000000002), // lo

// A is the first member of Mixed and has no extra clobbers. The class mask
// must nevertheless include B's clobbers.
// CHECK: static const LaneBitmask TestTargetWrittenLaneMaskRow[[MIXED]][] = {
// CHECK-NEXT: LaneBitmask(0x0000000000000003),
// CHECK-NEXT: LaneBitmask(0x0000000000000003),
// CHECK-NEXT: LaneBitmask(0x0000000000000003),
// CHECK-NEXT: };

// Writing either subregister of B overwrites both lanes. BOnly has its own row
// indexed by RC ID, even though the masks are identical to Mixed's.
// CHECK-NEXT: static const LaneBitmask TestTargetWrittenLaneMaskRow[[B]][] = {
// CHECK-NEXT: LaneBitmask(0x0000000000000003),
// CHECK-NEXT: LaneBitmask(0x0000000000000003),
// CHECK-NEXT: LaneBitmask(0x0000000000000003),
// CHECK-NEXT: };

// The AOnly class uses the default value masks because none of its registers have ClobberedBySubRegs=1
// CHECK-NEXT: static const LaneBitmask *const TestTargetWrittenLaneMaskTable[] = {
// CHECK-NEXT: TestTargetWrittenLaneMaskRow[[MIXED]],
// CHECK-NEXT: nullptr,
// CHECK-NEXT: TestTargetWrittenLaneMaskRow[[B]],
// CHECK-NEXT: };
