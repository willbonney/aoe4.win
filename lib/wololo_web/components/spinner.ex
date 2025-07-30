defmodule WololoWeb.Components.Spinner do
  use Phoenix.Component

  attr(:size, :string, default: "md")
  attr(:class, :string, default: "")

  def spinner(assigns) do
    ~H"""
    <div class={[
      "inline-block animate-spin rounded-full border-4 border-solid border-current border-r-transparent align-[-0.125em] motion-reduce:animate-[spin_1.5s_linear_infinite] text-stone-800 dark:text-slate-100",
      size_class(@size),
      @class
    ]}>
      <span class="!absolute !-m-px !h-px !w-px !overflow-hidden !whitespace-nowrap !border-0 !p-0 ![clip:rect(0,0,0,0)]">
        Loading...
      </span>
    </div>
    """
  end

  defp size_class("sm"), do: "h-4 w-4"
  defp size_class("md"), do: "h-8 w-8"
  defp size_class("lg"), do: "h-12 w-12"
  defp size_class(_), do: "h-8 w-8"
end
