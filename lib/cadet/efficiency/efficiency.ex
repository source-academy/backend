defmodule Cadet.Efficiency.Efficiency do
  @moduledoc """
  The Course entity stores the configuration of a particular course.
  """
  use Cadet, :model

  schema "efficiency" do
    field(:cid, :string)
    field(:sid, :string)
    field(:sname, :string)
    field(:time, :string)
    field(:runtimes, :integer)	
    field(:score, :integer)		
	
	
	

   

     
  end

 
  @required_fields ~w(cid sid sname avgtime runtimes )a
  
  
  def changeset(efficiency, params) do
    efficiency
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end

   
end
