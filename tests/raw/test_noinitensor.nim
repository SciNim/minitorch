import ../../flambeau/flambeau_raw
import std/macros

{.experimental: "views".} # TODO

macro `//`*(arg: string): untyped =
  let lit = newLit("/* " & arg.strVal() & " */")
  quote do:
    {.emit: `lit`.}

type
  TensorAgreggate*[T] {.requiresinit.} = object
    raw* : RawTensor

proc newTensorAggregate[T](): TensorAgreggate[T] {.constructor, noinit.} =
  {.emit: "/* */".}

proc newTensorAggregate[T](a: RawTensor): TensorAgreggate[T] {.noinit.} =
  result = newTensorAggregate[T]()
  result.raw = a

proc `$`*[T](tensorAg: TensorAgreggate[T]) : string =
  $(tensorAg.raw)

proc initTensorAggregate*[T](raw: RawTensor) : TensorAgreggate[T] {.noinit.} =
  assign(result.raw, raw)

proc main() =
  let a = [[1, 2], [3, 4]].toRawTensor()
  block:
    var b = a
    doAssert b == a
    doAssert $(b) == $(a)

  block:
    # "Create tensor"
    var rawtens : RawTensor = initRawTensor()
    let memdata = cast[ptr UncheckedArray[uint64]](rawtens.unsafeAddr)
    # Show casing that modifying the memdata[0] triggers the refcount
    let m = memdata[0]
    zeroMem(rawtens.unsafeAddr, sizeof(rawtens))
    # If this line is commentend, the line rawtens = a will detect a reference counting equal to zero and destroy the pointers before the assignment operator (causing a segfault)
    # This behaviour of zero-ing memory causing a ref. count is the reason why the {.noinit.} is needed on proc that return a Tensor
    memdata[0] = m # Comment to create a segfault
    rawtens = a
    doAssert rawtens == a
    doAssert $(rawtens) == $(a)

  block:
    var tensorAg : TensorAgreggate[int] = newTensorAggregate[int](a)
    doAssert tensorAg.raw == a
    doAssert $(tensorAg) == $(a)

  block:
    var tensorAg {.noinit.}: TensorAgreggate[int]
    tensorAg.raw = a
    doAssert tensorAg.raw == a
    doAssert $(tensorAg) == $(a)

main()
