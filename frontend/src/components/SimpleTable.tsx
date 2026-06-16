type Column<T> = {
  key: keyof T
  label: string
}

type Props<T extends Record<string, unknown>> = {
  columns: Array<Column<T>>
  rows: T[]
}

export default function SimpleTable<T extends Record<string, unknown>>({ columns, rows }: Props<T>) {
  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            {columns.map((column) => (
              <th key={String(column.key)}>{column.label}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, idx) => (
            <tr key={idx}>
              {columns.map((column) => (
                <td key={String(column.key)}>{String(row[column.key] ?? '-')}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
