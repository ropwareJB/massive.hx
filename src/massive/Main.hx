package massive;

import massive.MassiveMacro.*;

class ExampleModel{

  public var propertyA:Int;
  public var propertyB:Int;
  public var propertyC:Int;
  private var propertyD:Int;

  public function new(a:Int,b:Int,c:Int,d:Int){
    this.propertyA = a;
    this.propertyB = b;
    this.propertyC = c;
    this.propertyD = d;
  }

  public inline function scenario() return [
    "exampleScenario" => ["propertyB", "propertyC"]
  ];

  public function printMe(p:String){
    trace('$p propertyA: ${propertyA}');
    trace('$p propertyB: ${propertyB}');
    trace('$p propertyC: ${propertyC}');
    trace('$p propertyD: ${propertyD}');
  }

}

@:final class Main{

  public static function main():Void{
    var oldModel = new ExampleModel(1, 2, 3, 55);
    var newModel = new ExampleModel(3, 4, 10, 6);

    // Selective properties
    @:mass(propertyA, propertyB) oldModel = newModel;
    massAssign(oldModel, newModel, ["propertyA", "propertyB"]);

    @:scenario("exampleScenario") function closure(){
      @:mass oldModel = newModel;
    }
    closure();

    // Assign all properties
    @:mass oldModel = newModel;
    massAssign(oldModel, newModel, []);

    oldModel.printMe("oldModel");
  }

}
