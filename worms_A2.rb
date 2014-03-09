require 'matrix'

#help class
class Cell < Vector
  def x
    self[0]
  end
  def y
    self[1]
  end
end

# Movement constants
LEFT = Cell[-1,0]
RIGHT = Cell[1,0]
UP = Cell[0,-1]
DOWN = Cell[0,1]

class World
  attr_reader :worms
  attr_reader :width
  attr_reader :height
  attr_reader :mutex
  
  def initialize width, height
    @worms = []
    @width = width
    @height = height
    @mutexes = Matrix.build(@width,@height) {Mutex.new}
  end

  def place_meeting cell
    @worms.each do |w|
      if w.position == cell
        return w
      end
    end
    return nil
  end

  def mutex_at cell
    return @mutexes[cell.x,cell.y]
  end

  def add_worms n
    n.times do
      add_worm
    end
  end

  def add_worm
    @worms << Worm.new(@worms.size,self)
  end
end

class Worm < Thread
  attr_accessor :position
  attr_accessor :id
  attr_accessor :world

  def initialize id, world
    @id = id
    @world = world
    @mutex = nil
    self.position = Cell[0,0]
    super {step} #the step function runs in a new thread
  end

  def to_s
    (@id%93+65).chr #give every worm a distinct character
  end

  def step
    while true
      move
      sleep(0.003*rand(100))
    end
  end

  def move
    new_position = move_to                   # The worm is trying to go to 'new_position'.
    new_mutex = @world.mutex_at new_position # 'new_mutex' is the mutex at the 'new_position'.
    if new_mutex.try_lock                    # if possible, the worm acquires the lock at 'new_position'.
      self.position = new_position           # if the lock has been acquired, change inner position state accordingly.
      if @mutex                              # if the worm had the mutex at its old position, then unlock it.
        @mutex.unlock
      end
      @mutex = new_mutex                     # the current mutex is now the mutex at the 'new_position'.
    end
  end

  def move_to
    p = []
    if position.x > 0
      p << position + LEFT
    end
    if position.y > 0
      p << position + UP
    end
    if position.x < @world.width-1
      p << position + RIGHT
    end
    if position.y < @world.height-1
      p << position + DOWN
    end
    p.sample
  end
end

class Render
  attr_accessor :world

  def initialize world
    @world = world
  end

  def step
    while true
      puts draw
      puts clear
    end
  end

  def clear
    "\e[#{@world.height+1}A"
  end

  def draw 
    str = ""
    @world.height.times do |y|
      str += draw_row y
    end
    str
  end

  def draw_row y
    str = ""
    @world.width.times do |x|
      str += draw_cell(Cell[x,y])
    end
    str += "\n"
  end

  def draw_cell cell
    if worm = @world.place_meeting(cell)
      worm.to_s
    else
      "_"
    end
  end
end

puts "render"
world = World.new(ARGV[0].to_i,ARGV[1].to_i)
world.add_worms ARGV[2].to_i

r = Render.new world
r.step
