package;

import MassiveMacro.*;

class ExampleModel{

  public var propertyA:Int;
  public var propertyB:Int;
  public var propertyC:Int;

  public function new(a:Int,b:Int,c:Int){
    this.propertyA = a;
    this.propertyB = b;
    this.propertyC = c;
  }

}

@:final class Main{

  @:mass public static function main():Void{
    var oldModel = new ExampleModel(1, 2, 3);
    var newModel = new ExampleModel(3, 4, 10);

    // Selective properties
    @:mass(propertyA, propertyB) oldModel = newModel;
    massive(oldModel, newModel, ["propertyA", "propertyB"]);

    // Assign all properties
    @:mass oldModel = newModel;
    massive(oldModel, newModel);

    trace('oldModel propertyA: ${oldModel.propertyA}');
    trace('oldModel propertyB: ${oldModel.propertyB}');
    trace('oldModel propertyC: ${oldModel.propertyC}');
  }

}
