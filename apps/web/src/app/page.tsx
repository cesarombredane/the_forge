import { Box, Card, CardContent, Chip, Stack, Typography } from "@mui/material";

export default function HomePage() {
  return (
    <Box
      sx={{
        minHeight: "100vh",
        display: "grid",
        placeItems: "center",
        p: 3,
        background: "radial-gradient(circle at 15% 20%, #e8f0ff 0%, #f7f8fc 45%, #fff6eb 100%)"
      }}
    >
      <Card sx={{ maxWidth: 680, width: "100%", borderRadius: 4, boxShadow: 6 }}>
        <CardContent sx={{ p: 4 }}>
          <Stack spacing={2}>
            <Chip label="Architecture Baseline Ready" color="primary" sx={{ alignSelf: "flex-start" }} />
            <Typography variant="h3" sx={{ fontWeight: 700 }}>
              The Forge
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Frontend service is live with Next.js + MUI. API and database wiring will power workouts,
              sessions, and progression.
            </Typography>
          </Stack>
        </CardContent>
      </Card>
    </Box>
  );
}
